# Challenge: Crescent Moon

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// The moon disc (radius 0.65) and the circle that cuts it (radius 0.55, offset up and right)
float moon = length(uv) - 0.65;
float cut = length(uv - vec2(0.3, 0.12)) - 0.55;

// Subtract the cut from the moon
float d = max(moon, -cut);

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Cut circle offset the wrong way, wrong radii (too fat or too thin a crescent), or a full disc.
