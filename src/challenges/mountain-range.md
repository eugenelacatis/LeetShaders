# Challenge: Mountain Range

A capstone mixing noise (value noise, fBm) and raymarching (normals from a distance function). The starter in `mountain-range.starter.glsl` locks the hash, the octave rotation `ROT`, the camera, sky, sun, height-field march, materials and fog. The learner fills three cells. The reference is the starter with the cells solved; the locked code must match (`src/challenges/capstones.test.ts`).

## Intended Solution

```glsl
// @cell Value noise
float noise(vec2 p) {
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + ivec2(1, 0));
    float c = hash(i + ivec2(0, 1));
    float d = hash(i + ivec2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// @cell Terrain height
float terrain(vec2 p) {
    p *= 0.35;
    float sum = 0.0;
    float amp = 0.5;
    for (int o = 0; o < 5; o++) {
        sum += amp * noise(p);
        p = ROT * p * 2.0;
        amp *= 0.5;
    }
    float h = sum / 0.96875;
    return 2.2 * h * h;
}

// @cell Surface normal
vec3 terrainNormal(vec3 p) {
    const float e = 0.01;
    return normalize(vec3(
        terrain(p.xz - vec2(e, 0.0)) - terrain(p.xz + vec2(e, 0.0)),
        2.0 * e,
        terrain(p.xz - vec2(0.0, e)) - terrain(p.xz + vec2(0.0, e))
    ));
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Cost:** SwiftShader at 512x512, 106 to 173ms warm (about 280ms cold). Apple M1 (Metal) 12 to 19ms. Byte-identical on repeat.
- **Cross-GPU:** SwiftShader vs Apple M1 Metal, raw MAE 0.000 at t = 0 and 0.001 at t = 37 (blurred the same). The PCG hash and integer lattice keep the height field identical across GPUs.
- **Animation:** the camera moves toward -z at 0.4 units a second (locked), so t = 0 and t = 37 differ by raw 16.1. The static-frame cheat (t = 0 frame, `u_time` removed) should fail at the random samples.
- **Grazing rays:** a ray that runs out of its 80 steps counts as ground, not sky. Counting it as sky left thin sky-colored seams along the ridges.
- **Near misses:** forward differences or e = 0.005 / 0.02 for the normal; 4 or 6 octaves; scale 0.33 or 0.37; no squaring (rounder hills, less snow). **Wrongs:** a terrain cell left as the TODO (flat ground), no `ROT`, `sin` hash noise, the normal left as (0, 1, 0) (flat shading), the locked camera edited.
