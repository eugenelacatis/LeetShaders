// Shared sources for the landing demos. Everything renders through src/judge/pipeline.ts.

// A near miss of the raymarched-sphere reference: the light sits a little lower and the
// highlight is softer.
export function nearMiss(src: string): string {
  return src
    .replace('vec3(2.0, 4.0, 5.0)', 'vec3(4.0, 2.5, 4.0)')
    .replace('vec3(0.4, 0.6, 0.9)', 'vec3(0.5, 0.55, 0.95)')
    .replace('32.0', '16.0');
}

// The near miss with its light following u_mouse, so different inputs give visibly
// different renders.
export function mouseLit(nearMissSrc: string): string {
  return nearMissSrc.replace(
    'vec3(4.0, 2.5, 4.0)',
    'vec3((u_mouse / u_resolution - 0.5) * 8.0, 4.0)',
  );
}

// Fixed demo mouse positions (0 to 1). These are not the judge's real seeds.
export const DEMO_INPUTS: [number, number][] = [
  [0.72, 0.78],
  [0.22, 0.64],
  [0.58, 0.2],
  [0.3, 0.3],
  [0.85, 0.45],
];
