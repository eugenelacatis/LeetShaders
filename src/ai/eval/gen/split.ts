// Seeded, stratified 150 / 50 tuning / held-out split.
//
//   npx tsx src/ai/eval/gen/split.ts
//
// Each (challenge x category) cell of 10 fixtures gives 2 or 3 to held-out,
// alternating by cell, so the totals land at exactly 150 / 50 for 200
// fixtures. Never tune on the held-out set.

import { writeFile } from 'node:fs/promises';
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

async function main(): Promise<void> {
  const challenges = await loadChallenges();
  const fixtures = await discoverFixtures(new Set(challenges.keys()));
  const rand = mulberry32(SEED);
  const tuning: string[] = [];
  const heldout: string[] = [];

  let cellIndex = 0;
  for (const challengeId of [...challenges.keys()].sort()) {
    for (const verdict of VERDICTS) {
      const cell: Fixture[] = fixtures.filter(
        (f) => f.challengeId === challengeId && f.verdict === verdict,
      );
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
  }

  tuning.sort();
  heldout.sort();
  await writeFile(
    join(FIXTURES_DIR, 'split.json'),
    JSON.stringify({ seed: SEED, tuning, heldout }, null, 2) + '\n',
  );
  console.log(`tuning ${tuning.length}, heldout ${heldout.length}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
