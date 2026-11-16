# Challenge: Slant

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

// 0.0 at the bottom-left corner, 1.0 at the top-right corner
float t = (uv.x + uv.y) * 0.5;

vec3 color = mix(vec3(1.0, 0.6, 0.1), vec3(0.8, 0.1, 0.6), t);

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** a horizontal or vertical blend, or the diagonal running the other way.
