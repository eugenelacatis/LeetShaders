# Challenge: Pinstripe

## Intended Solution

```glsl
vec2 uv = gl_FragCoord.xy / u_resolution.xy;

vec3 cream = vec3(0.96, 0.92, 0.82);
vec3 navy = vec3(0.1, 0.13, 0.25);

// Six repeats across the canvas. fract() restarts the 0 to 1 ramp each time
float t = fract(uv.x * 6.0);

// First half of each repeat is cream, second half is navy
vec3 color = mix(cream, navy, step(0.5, t));

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong stripe count, colors swapped, stripes running the other way, or a smooth blend instead of hard edges.
