// Fixture discovery shared by run.ts and the generators in gen/.
//
// Layout: fixtures/challenges/<id>.{glsl,json} plus
// fixtures/<verdict>/<id>-<label>.glsl. See fixtures/README.md.

import { readdir, readFile } from 'node:fs/promises';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Challenge } from '../../judge/types';

export const FIXTURES_DIR = join(dirname(fileURLToPath(import.meta.url)), 'fixtures');

export type Verdict = 'correct' | 'almost-correct' | 'wrong' | 'adversarial';
export const VERDICTS: readonly Verdict[] = ['correct', 'almost-correct', 'wrong', 'adversarial'];

export interface Fixture {
  key: string; // `${verdict}/${stem}`
  verdict: Verdict;
  challengeId: string;
  label: string;
  sourcePath: string;
}

export async function loadChallenges(): Promise<Map<string, Challenge>> {
  const dir = join(FIXTURES_DIR, 'challenges');
  const map = new Map<string, Challenge>();
  for (const f of (await readdir(dir)).filter((f) => f.endsWith('.json'))) {
    const meta = JSON.parse(await readFile(join(dir, f), 'utf8')) as Omit<
      Challenge,
      'referenceShaderSrc'
    >;
    const referenceShaderSrc = await readFile(join(dir, `${meta.id}.glsl`), 'utf8');
    map.set(meta.id, { ...meta, referenceShaderSrc });
  }
  return map;
}

export async function discoverFixtures(knownIds: Set<string>): Promise<Fixture[]> {
  const out: Fixture[] = [];
  for (const verdict of VERDICTS) {
    const dir = join(FIXTURES_DIR, verdict);
    let entries: string[];
    try {
      entries = (await readdir(dir)).sort();
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (!entry.endsWith('.glsl')) continue;
      const stem = basename(entry, '.glsl');
      const challengeId = [...knownIds]
        .filter((id) => stem.startsWith(`${id}-`))
        .sort((a, b) => b.length - a.length)[0];
      if (!challengeId) {
        console.warn(`[eval] skipping ${verdict}/${entry}: no matching challenge id prefix`);
        continue;
      }
      out.push({
        key: `${verdict}/${stem}`,
        verdict,
        challengeId,
        label: stem.slice(challengeId.length + 1),
        sourcePath: join(dir, entry),
      });
    }
  }
  return out;
}

