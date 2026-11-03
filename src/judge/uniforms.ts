import { CANVAS_SIZE, type Uniforms } from './pipeline';
import { mulberry32 } from './prng';

export { mulberry32 } from './prng';

// Seeded uniform sampling for the judge. Rendering both shaders at several
// (u_time, u_mouse) points catches submissions that only match the reference
// at the default inputs, e.g. `if (u_time == 0.0) { ...reference... }`.
//
// Production draws a fresh seed per submission; the eval harness uses a fixed
// seed and prints it in REPORT.md so runs are reproducible.

export const DEFAULT_SAMPLE_COUNT = 4;
const MAX_TIME = 60;

/**
 * Sample 0 is always the defaults ({}), so a correct shader is judged at the
 * same inputs the live preview shows. The rest are random.
 */
export function sampleUniforms(seed: number, n: number = DEFAULT_SAMPLE_COUNT): Uniforms[] {
  const rand = mulberry32(seed);
  const samples: Uniforms[] = [{}];
  for (let i = 1; i < n; i++) {
    samples.push({
      u_time: rand() * MAX_TIME,
      u_mouse: [rand() * CANVAS_SIZE, rand() * CANVAS_SIZE],
    });
  }
  return samples;
}

/** Fresh 32-bit seed for a production submission. */
export function freshSeed(): number {
  return crypto.getRandomValues(new Uint32Array(1))[0] ?? 0;
}
