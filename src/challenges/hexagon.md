# Challenge: Hexagon

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Regular hexagon with flat top and bottom, 0.5 from center to each edge.
// Three edge directions cover all six sides because abs() mirrors each one.
vec2 n1 = vec2(1.0, 0.0);
vec2 n2 = vec2(0.5, 0.866025);
vec2 n3 = vec2(-0.5, 0.866025);
float d = max(abs(dot(uv, n1)), max(abs(dot(uv, n2)), abs(dot(uv, n3)))) - 0.5;

// Inside the shape (d < 0) is white, outside is black
float mask = 1.0 - smoothstep(-0.01, 0.01, d);

fragColor = vec4(vec3(mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** A pointy top instead of a flat top, the wrong size, or a wrong direction set.
