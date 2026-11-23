import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { lockedText, parseCells } from '../editor/cellParse';

// A capstone's reference is its starter with every cell solved, so everything
// outside the cells must be identical in both files.
const DIR = join(process.cwd(), 'src', 'challenges');
const starters = readdirSync(DIR).filter((f) => f.endsWith('.starter.glsl'));

describe('capstone starters', () => {
  it('exist', () => {
    expect(starters.length).toBeGreaterThan(0);
  });

  it.each(starters)('%s matches its reference outside the cells', (file) => {
    const starter = parseCells(readFileSync(join(DIR, file), 'utf8'));
    const reference = parseCells(
      readFileSync(join(DIR, file.replace('.starter.glsl', '.glsl')), 'utf8'),
    );

    const cells = (segs: typeof starter) =>
      segs.flatMap((s) => (s.kind === 'cell' ? [s.head.join('\n')] : []));
    expect(cells(starter).length).toBeGreaterThan(0);
    expect(cells(reference)).toEqual(cells(starter));
    expect(lockedText(reference)).toBe(lockedText(starter));
  });
});
