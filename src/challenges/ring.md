# Challenge: Ring

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to a circle of radius 0.55, then thickened to a band
// that reaches 0.12 to each side of it
float d = abs(length(uv) - 0.55) - 0.12;

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong radius, a band that is too thin or too thick, or a filled disc.
