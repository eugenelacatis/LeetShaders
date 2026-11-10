import { TRACKS } from '../judge/types';
import type { Challenge } from '../judge/types';

// The learning path: the order challenges appear on each board.
// Slugs not listed here fall to the end of their board, easiest first.
export const PATH_ORDER: readonly string[] = [
  // color
  'solid-color',
  'uv-gradient',
  'radial-gradient',
  'hsv-color-wheel',
  // shapes
  'circle-sdf',
  'box-sdf',
  // patterns
  'checkerboard',
  'polar-pattern',
  // raymarching
  'raymarched-sphere',
];

export const RANK: Record<Challenge['difficulty'], number> = {
  beginner: 1,
  intermediate: 2,
  advanced: 3,
  expert: 4,
};

// Listed slugs follow PATH_ORDER; unlisted ones go after them, easiest first.
function pathIndex(c: Challenge): number {
  const i = PATH_ORDER.indexOf(c.slug);
  return i === -1 ? PATH_ORDER.length : i;
}

export function byPath(a: Challenge, b: Challenge): number {
  return (
    pathIndex(a) - pathIndex(b) ||
    RANK[a.difficulty] - RANK[b.difficulty] ||
    a.title.localeCompare(b.title)
  );
}

/** The challenge after `current` on the full path: boards in track order, then path order. */
export function nextOnPath(all: Challenge[], current: Challenge): Challenge | null {
  const ordered = [...all].sort(
    (a, b) => TRACKS.indexOf(a.track) - TRACKS.indexOf(b.track) || byPath(a, b),
  );
  const i = ordered.findIndex((c) => c.id === current.id);
  return i === -1 ? null : (ordered[i + 1] ?? null);
}
