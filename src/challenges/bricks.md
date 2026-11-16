# Challenge: Brickwork

## Intended Solution

```glsl
// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Four bricks across, eight rows up. floor() on y gives the row number
vec2 p = uv * vec2(2.0, 4.0);
float row = floor(p.y);

// Every second row slides half a brick sideways
p.x += 0.5 * mod(row, 2.0);
vec2 f = fract(p);

// Mortar lines sit at the left and bottom edge of each brick
float mx = smoothstep(0.04, 0.06, f.x);
float my = smoothstep(0.08, 0.1, f.y);
float brick = mx * my;

vec3 mortar = vec3(0.85, 0.82, 0.75);
vec3 red = vec3(0.7, 0.28, 0.2);

fragColor = vec4(mix(mortar, red, brick), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** No row offset (a plain grid), the offset on the wrong rows, or mortar widths swapped.
