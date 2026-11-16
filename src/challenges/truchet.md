# Challenge: Maze Runner

## Intended Solution

```glsl
// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// Aspect-ratio corrected UVs, centered, -1 to 1
vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

// Six by six tiles. Each tile has its own integer id and its own 0 to 1 coordinates
vec2 p = uv * 3.0;
ivec2 id = ivec2(floor(p));
vec2 f = fract(p);

// The hash picks one of two flips per tile
uint h = pcg(pcg(uint(id.x)) + uint(id.y));
if ((h & 1u) == 1u) f.x = 1.0 - f.x;

// Quarter circle arcs of radius 0.5 around two opposite corners
float d = min(abs(length(f) - 0.5), abs(length(f - 1.0) - 0.5));
float mask = 1.0 - smoothstep(0.07, 0.09, d);

vec3 cream = vec3(0.96, 0.92, 0.82);
vec3 ink = vec3(0.1, 0.12, 0.25);

fragColor = vec4(mix(cream, ink, mask), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Hash applied in a different order, a different bit chosen, tiles not flipped at all (a plain grid of arcs), or arc width off.
