import { describe, expect, it } from 'vitest';
import { cellLineOffsets, errorsForCell, joinCells, lockedText, parseCells } from './cellParse';

const SRC = [
  'void main() {',
  '  // locked camera',
  '// @cell Sky color',
  '// @numbers Horizon is 0.9.',
  '// @numbers Zenith is 0.2.',
  '  vec3 sky = vec3(0.0);',
  '  sky += 0.1;',
  '// @end',
  '  // locked march',
  '// @cell Fog',
  '  float fog = 0.0;',
  '// @end',
  '}',
].join('\n');

describe('parseCells', () => {
  it('splits a starter into locked parts and cells', () => {
    const segs = parseCells(SRC);
    expect(segs.map((s) => s.kind)).toEqual(['locked', 'cell', 'locked', 'cell', 'locked']);
    const sky = segs[1];
    expect(sky.kind === 'cell' && sky.title).toBe('Sky color');
    expect(sky.kind === 'cell' && sky.numbers).toBe('Horizon is 0.9. Zenith is 0.2.');
    expect(sky.kind === 'cell' && sky.body).toEqual(['  vec3 sky = vec3(0.0);', '  sky += 0.1;']);
  });

  it('round-trips the source exactly', () => {
    expect(joinCells(parseCells(SRC))).toBe(SRC);
  });

  it('treats a source with no cells as one locked part', () => {
    const segs = parseCells('void main() {}');
    expect(segs).toEqual([{ kind: 'locked', lines: ['void main() {}'] }]);
  });

  it('ignores an unterminated cell', () => {
    expect(parseCells('// @cell Open\nfloat a;').every((s) => s.kind === 'locked')).toBe(true);
  });
});

describe('cell offsets and errors', () => {
  it('maps full-source lines to each cell editor', () => {
    const segs = parseCells(SRC);
    expect(cellLineOffsets(segs)).toEqual([5, 10]);
    const errs = [
      { kind: 'compile-error' as const, line: 7, message: 'in sky' },
      { kind: 'compile-error' as const, line: 2, message: 'locked' },
    ];
    expect(errorsForCell(errs, 5, 2)).toEqual([{ kind: 'compile-error', line: 2, message: 'in sky' }]);
    expect(errorsForCell(errs, 10, 1)).toEqual([]);
  });

  it('collects the locked text for the reveal', () => {
    expect(lockedText(parseCells(SRC))).toContain('// locked march');
  });
});
