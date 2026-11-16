# Challenge: Split Decision

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

vec3 left = vec3(0.9, 0.22, 0.27);
vec3 right = vec3(0.1, 0.13, 0.25);

// step() returns 0.0 left of the edge and 1.0 from the edge on
vec3 color = mix(left, right, step(0.5, uv.x));

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** edge at 0.45 or 0.55, or a smooth blend instead of a hard cut.
