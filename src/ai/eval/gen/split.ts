// Seeded, stratified tuning / held-out split (75% / 25%).
//
//   npx tsx src/ai/eval/gen/split.ts
//
// Each (challenge x category) cell of 10 fixtures gives 2 or 3 to held-out,
// alternating by cell, so totals land at exactly 3:1 for an even number of
// cells. Never tune on the held-out set.
//
// Assignments are sticky: a fixture already in split.json keeps its side, so
// adding challenges never moves a tuned-on fixture into held-out. Only cells
// with no assigned fixtures are split, continuing the alternation.

import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { mulberry32 } from '../../../judge/prng';
import {
  FIXTURES_DIR,
  VERDICTS,
  discoverFixtures,
  loadChallenges,
  type Fixture,
} from '../fixtures';

const SEED = 20261102;
const SPLIT_PATH = join(FIXTURES_DIR, 'split.json');

interface Split {
  seed: number;
  tuning: string[];
  heldout: string[];
}

async function readExisting(): Promise<Split | null> {
  try {
    return JSON.parse(await readFile(SPLIT_PATH, 'utf8')) as Split;
  } catch {
    return null;
  }
}

async function main(): Promise<void> {
  const challenges = await loadChallenges();
  const fixtures = await discoverFixtures(new Set(challenges.keys()));
  const existing = await readExisting();
  const keys = new Set(fixtures.map((f) => f.key));
  // Drop keys for fixtures that no longer exist.
  const tuning = (existing?.tuning ?? []).filter((k) => keys.has(k));
  const heldout = (existing?.heldout ?? []).filter((k) => keys.has(k));
  const assigned = new Set([...tuning, ...heldout]);

  const cells: Fixture[][] = [];
  for (const challengeId of [...challenges.keys()].sort()) {
    for (const verdict of VERDICTS) {
      cells.push(fixtures.filter((f) => f.challengeId === challengeId && f.verdict === verdict));
    }
  }

  // Cells that already have assignments keep them, and count toward the
  // alternation so it continues where it left off.
  const done = cells.filter((cell) => cell.some((f) => assigned.has(f.key)));
  for (const cell of done) {
    const stray = cell.filter((f) => !assigned.has(f.key));
    if (stray.length) {
      throw new Error(
        `cell ${cell[0]!.challengeId}/${cell[0]!.verdict} has unassigned fixtures: ${stray.map((f) => f.key).join(', ')}`,
      );
    }
  }

  const rand = mulberry32(SEED);
  let cellIndex = done.length;
  for (const cell of cells.filter((c) => !done.includes(c))) {
    // Fisher-Yates with the seeded PRNG.
    for (let i = cell.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [cell[i], cell[j]] = [cell[j]!, cell[i]!];
    }
    const nHeld = Math.round(cell.length * (cellIndex % 2 === 0 ? 0.2 : 0.3));
    heldout.push(...cell.slice(0, nHeld).map((f) => f.key));
    tuning.push(...cell.slice(nHeld).map((f) => f.key));
    cellIndex++;
  }

  tuning.sort();
  heldout.sort();
  await writeFile(SPLIT_PATH, JSON.stringify({ seed: SEED, tuning, heldout }, null, 2) + '\n');
  console.log(`tuning ${tuning.length}, heldout ${heldout.length}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
