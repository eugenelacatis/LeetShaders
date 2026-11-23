import { TRACKS } from '../judge/types';
import type { Challenge } from '../judge/types';

// The learning path: the order challenges appear on each board.
// Slugs not listed here fall to the end of their board, easiest first.
export const PATH_ORDER: readonly string[] = [
  // color
  'solid-color',
  'split-decision',
  'uv-gradient',
  'slant',
  'staircase',
  'radial-gradient',
  'vignette',
  'golden-hour',
  'hsv-color-wheel',
  'cosine-sunset',
  // shapes
  'circle-sdf',
  'ring',
  'box-sdf',
  'line-segment',
  'triangle',
  'hexagon',
  'star',
  'heart',
  'crescent-moon',
  'clock-face',
  // combining
  'union',
  'intersection',
  'subtraction',
  'smooth-union',
  'onion-rings',
  'outlined-shape',
  'glow',
  'drop-shadow',
  'lava-lamp',
  // patterns
  'stripes',
  'zigzag',
  'polka-dots',
  'concentric-rings',
  'bricks',
  'checkerboard',
  'spiral',
  'hex-grid',
  'truchet',
  'polar-pattern',
  'kaleidoscope',
  'woven-truchet',
  // noise
  'white-noise',
  'value-noise',
  'voronoi',
  'worley-cracks',
  'fbm-clouds',
  'marble',
  'domain-warp',
  // raymarching
  'raymarched-sphere',
  'raymarched-box',
  'raymarched-torus',
  'raymarched-capsule',
  'hard-shadow',
  'soft-shadow',
  'ambient-occlusion',
  'smooth-blobs',
  'repeated-spheres',
  'fog',
  'reflections',
  'the-full-scene',
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
