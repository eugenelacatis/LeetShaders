# Challenge: Soft Shadow

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Rounded box, half-size (0.45, 0.3), corner radius 0.1
vec2 q = abs(uv) - vec2(0.45, 0.3) + 0.1;
float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.1;

// The same box, moved right and down. The wide smoothstep is the blur
vec2 qs = abs(uv - vec2(0.08, -0.1)) - vec2(0.45, 0.3) + 0.1;
float ds = length(max(qs, 0.0)) + min(max(qs.x, qs.y), 0.0) - 0.1;
float shadow = 1.0 - smoothstep(-0.12, 0.12, ds);

vec3 paper = vec3(0.93, 0.92, 0.9);
vec3 coral = vec3(0.95, 0.4, 0.35);

// Shadow darkens the paper by up to 45 percent, then the box covers it
vec3 color = paper * (1.0 - 0.45 * shadow);
float mask = 1.0 - smoothstep(-0.01, 0.01, d);
color = mix(color, coral, mask);

fragColor = vec4(color, 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** A hard-edged shadow, a shadow with no offset, or one drawn on top of the box.
