# Challenge: Value Noise

## Intended Solution

```glsl
// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// One random number in [0, 1) per lattice corner
float hash(ivec2 c) {
    uint h = pcg(pcg(uint(c.x)) + uint(c.y));
    return float(h >> 8) / 16777216.0;
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // 8 by 8 lattice cells: floor() picks the cell, fract() is the spot inside it
    vec2 p = uv * 4.0;
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);

    // Smoothstep curve so the slope is zero at every lattice line
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Blend the four corner values across x, then across y
    float a = hash(i);
    float b = hash(i + ivec2(1, 0));
    float c = hash(i + ivec2(0, 1));
    float d = hash(i + ivec2(1, 1));
    float n = mix(mix(a, b, u.x), mix(c, d, u.x), u.y);

    fragColor = vec4(vec3(n), 1.0);
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** Wrong seed, 4 by 4 or 16 by 16 cells, linear blend instead of smoothstep (visible creases), x and y swapped, or a sin() hash.
