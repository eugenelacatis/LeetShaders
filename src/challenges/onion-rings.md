# Challenge: Onion Rings

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Start from a circle of radius 0.6
float d = length(uv) - 0.6;

// Onion once: abs() folds inside and outside together, then subtracting 0.15 thickens the edge into a band
d = abs(d) - 0.15;

// Onion again: the band has two edges, so this makes an outline around each, 0.04 to each side
d = abs(d) - 0.04;

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Only one onion pass (a single thick ring), wrong widths, or a filled disc.
