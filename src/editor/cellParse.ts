import type { PipelineError } from '../judge/types';

/**
 * A capstone starter is a full shader. Regions the learner fills in are wrapped
 * in comment directives, so the source stays valid GLSL and line numbers match
 * what the compiler reports:
 *
 *   // @cell Sky color
 *   // @numbers Horizon is (0.9, 0.6, 0.4). Zenith is (0.2, 0.4, 0.8).
 *   <editable lines>
 *   // @end
 *
 * Everything outside a cell is locked.
 */
export type Segment =
  | { kind: 'locked'; lines: string[] }
  | { kind: 'cell'; title: string; numbers: string; head: string[]; body: string[]; tail: string };

const CELL = /^\s*\/\/\s*@cell\s+(.+?)\s*$/;
const NUMBERS = /^\s*\/\/\s*@numbers\s+(.+?)\s*$/;
const END = /^\s*\/\/\s*@end\s*$/;

export function parseCells(src: string): Segment[] {
  const lines = src.split('\n');
  const out: Segment[] = [];
  let locked: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const open = CELL.exec(lines[i]);
    const endAt = open ? lines.findIndex((l, j) => j > i && END.test(l)) : -1;
    if (!open || endAt === -1) {
      locked.push(lines[i]);
      i++;
      continue;
    }
    if (locked.length) out.push({ kind: 'locked', lines: locked });
    locked = [];
    const head = [lines[i]];
    const numbers: string[] = [];
    i++;
    while (i < endAt) {
      const n = NUMBERS.exec(lines[i]);
      if (!n) break;
      head.push(lines[i]);
      numbers.push(n[1]);
      i++;
    }
    out.push({
      kind: 'cell',
      title: open[1],
      numbers: numbers.join(' '),
      head,
      body: lines.slice(i, endAt),
      tail: lines[endAt],
    });
    i = endAt + 1;
  }
  if (locked.length) out.push({ kind: 'locked', lines: locked });
  return out;
}

export function joinCells(segments: Segment[]): string {
  return segments
    .flatMap((s) => (s.kind === 'locked' ? s.lines : [...s.head, ...s.body, s.tail]))
    .join('\n');
}

/** Lines before each cell's first editable line, in segment order (cells only). */
export function cellLineOffsets(segments: Segment[]): number[] {
  const offsets: number[] = [];
  let line = 0;
  for (const s of segments) {
    if (s.kind === 'locked') {
      line += s.lines.length;
    } else {
      line += s.head.length;
      offsets.push(line);
      line += s.body.length + 1;
    }
  }
  return offsets;
}

/** Errors inside one cell, with line numbers relative to that cell's editor. */
export function errorsForCell(errors: PipelineError[], offset: number, bodyLines: number): PipelineError[] {
  return errors
    .filter((e) => e.line != null && e.line > offset && e.line <= offset + bodyLines)
    .map((e) => ({ ...e, line: e.line! - offset }));
}

export function lockedText(segments: Segment[]): string {
  return segments
    .filter((s): s is Extract<Segment, { kind: 'locked' }> => s.kind === 'locked')
    .map((s) => s.lines.join('\n').trim())
    .join('\n\n// ...\n\n');
}
