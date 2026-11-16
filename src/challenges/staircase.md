# Challenge: Staircase

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

// Five bands, bottom to top: floor() snaps the smooth ramp to steps
float band = floor(uv.y * 5.0) / 4.0;

fragColor = vec4(vec3(band), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** four or six bands, or bands that don't reach full white at the top.
