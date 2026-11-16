# Challenge: Neon Halo

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to the disc's edge, radius 0.3
float d = length(uv) - 0.3;

// Glow: strongest at the edge, fading with exp(). max() keeps it from growing inside the disc
float glow = exp(-5.0 * max(d, 0.0));

vec3 bg = vec3(0.02, 0.02, 0.08);
vec3 color = bg + vec3(1.0, 0.55, 0.15) * glow * 0.9;

// White disc on top
float mask = 1.0 - smoothstep(-0.01, 0.01, d);
color = mix(color, vec3(1.0), mask);

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong falloff rate (glow too tight or too wide), no glow, glow drawn over the disc, or the wrong color.
