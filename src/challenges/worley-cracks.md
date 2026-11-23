# Challenge: Cracked Earth

## Intended Solution

```glsl
// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// Worley cracks: F2 - F1 is near zero only where two feature points are almost equally close
void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // 8 by 8 cells
    vec2 p = uv * 4.0;
    ivec2 i = ivec2(floor(p));

    // F1 is the nearest feature point distance, F2 the second nearest
    float f1 = 1e9;
    float f2 = 1e9;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            ivec2 c = i + ivec2(x, y);
            uint h = pcg(pcg(uint(c.x)) + uint(c.y));
            vec2 point = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
            float d = distance(p, point);
            if (d < f1) {
                f2 = f1;
                f1 = d;
            } else if (d < f2) {
                f2 = d;
            }
        }
    }

    // Crack is 1 on the cell border and fades to 0 over 0.1 of F2 - F1
    float crack = 1.0 - smoothstep(0.0, 0.1, f2 - f1);

    vec3 stone = vec3(0.84, 0.79, 0.70);
    vec3 dark = vec3(0.10, 0.08, 0.07);
    fragColor = vec4(mix(stone, dark, crack), 1.0);
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** F1 shown instead of F2 - F1, crack width off, wrong scale, a cell-color fill instead of cracks, or a baked crack mask.
