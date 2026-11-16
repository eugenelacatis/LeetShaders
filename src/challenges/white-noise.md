# Challenge: TV Static

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

// A 32 by 32 grid of cells. floor() gives every cell an integer id
ivec2 cell = ivec2(floor(uv * 16.0));

// Hash the id into a random uint, with no sin() and no floats until the end
uint h = pcg(pcg(uint(cell.x)) + uint(cell.y));

// Keep the top 24 bits so the uint to float conversion is exact
float grey = float(h >> 8) / 16777216.0;

fragColor = vec4(vec3(grey), 1.0);
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong seed or cell size, a different hash, x and y swapped, or a sin() hash that matches at one resolution but not another.
