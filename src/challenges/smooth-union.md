# Challenge: Melting Pair

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Distance to each circle: radius 0.35, centers at (-0.35, 0) and (0.35, 0)
float d1 = length(uv - vec2(-0.35, 0.0)) - 0.35;
float d2 = length(uv - vec2(0.35, 0.0)) - 0.35;

// Polynomial smooth minimum, blend width 0.3. h is 0 far from the crease and 1 right on it
float k = 0.3;
float h = max(k - abs(d1 - d2), 0.0) / k;
float d = min(d1, d2) - h * h * k * 0.25;

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Hard min() with no neck, a blend width that is too small or too large, or circles moved.
