# Challenge: Golden Hour

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

vec3 bottom = vec3(0.98, 0.45, 0.1);
vec3 middle = vec3(0.95, 0.75, 0.35);
vec3 top = vec3(0.25, 0.3, 0.6);

// Two blends stacked: bottom to middle over the lower half, middle to top over the upper half
vec3 color = mix(bottom, middle, smoothstep(0.0, 0.5, uv.y));
color = mix(color, top, smoothstep(0.5, 1.0, uv.y));

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** gold stop not at 0.5, or a hard seam between the two blends.
