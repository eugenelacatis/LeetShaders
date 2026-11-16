# Challenge: Bite Mark

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to the disc (radius 0.6) and to the bite (radius 0.4 at x = 0.4)
float disc = length(uv) - 0.6;
float bite = length(uv - vec2(0.4, 0.0)) - 0.4;

// Subtraction: negating the bite turns its inside into outside, then max() keeps only the disc part outside it
float d = max(disc, -bite);

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Bite on the wrong side, wrong radius, or the bite kept instead of removed.
