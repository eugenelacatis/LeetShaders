# Challenge: Ripple

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance from the center, scaled so there are four repeats from center to edge
float r = length(uv) * 4.0;

// fract() repeats 0 to 1. abs(fract() - 0.5) makes equal-width bands
float band = smoothstep(0.24, 0.26, abs(fract(r) - 0.5));

vec3 indigo = vec3(0.15, 0.1, 0.45);
vec3 peach = vec3(1.0, 0.8, 0.65);

fragColor = vec4(mix(indigo, peach, band), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong ring count, rings centered off the canvas center, or colors swapped.
