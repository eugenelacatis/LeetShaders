# Challenge: Vignette

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

vec3 base = vec3(0.95, 0.85, 0.6);

// Distance from the center of the canvas
float d = length(uv - 0.5);

// 1.0 in the middle, falling to 0.0 at distance 0.75
float v = 1.0 - smoothstep(0.25, 0.75, d);

fragColor = vec4(base * v, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** a linear falloff instead of smoothstep, or the smoothstep range shifted.
