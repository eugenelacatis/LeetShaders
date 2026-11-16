# Challenge: Lens

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to each circle: radius 0.55, centers at (-0.25, 0) and (0.25, 0)
float d1 = length(uv - vec2(-0.25, 0.0)) - 0.55;
float d2 = length(uv - vec2(0.25, 0.0)) - 0.55;

// Intersection: a point is inside only if it is inside both, so keep the larger distance
float d = max(d1, d2);

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** min() instead of max() (both circles instead of the overlap), wrong radius, or centers moved.
