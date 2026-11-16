# Challenge: Whirlpool

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance and angle around the center, angle turned into 0 to 1 turns
float r = length(uv);
float turns = atan(uv.y, uv.x) / 6.2831853;

// Rings are fract(r * 3). Subtracting the angle slides each ring around, so they join into one spiral
float v = r * 3.0 - turns;
float band = smoothstep(0.24, 0.26, abs(fract(v) - 0.5));

vec3 plum = vec3(0.2, 0.05, 0.3);
vec3 pink = vec3(1.0, 0.45, 0.7);

fragColor = vec4(mix(plum, pink, band), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Plain rings (no angle term), a spiral winding the other way (angle added), or the wrong number of arms.
