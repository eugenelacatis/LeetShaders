# Challenge: Double Bubble

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to each circle: radius 0.4, centers at (-0.3, 0) and (0.3, 0)
float d1 = length(uv - vec2(-0.3, 0.0)) - 0.4;
float d2 = length(uv - vec2(0.3, 0.0)) - 0.4;

// Union: a point is inside if it is inside either circle, so keep the smaller distance
float d = min(d1, d2);

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong radius, centers too far apart so the circles do not overlap, or max() instead of min() (which gives the lens in the middle).
