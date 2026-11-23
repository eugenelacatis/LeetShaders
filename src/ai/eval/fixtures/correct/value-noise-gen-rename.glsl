#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

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
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // 8 by 8 lattice cells: floor() picks the cell, fract() is the spot inside it
    vec2 pos = st * 4.0;
    ivec2 cell = ivec2(floor(pos));
    vec2 frac = fract(pos);

    // Smoothstep curve so the slope is zero at every lattice line
    vec2 w = frac * frac * (3.0 - 2.0 * frac);

    // Blend the four corner values across x, then across y
    float a = hash(cell);
    float b = hash(cell + ivec2(1, 0));
    float c = hash(cell + ivec2(0, 1));
    float d = hash(cell + ivec2(1, 1));
    float value = mix(mix(a, b, w.x), mix(c, d, w.x), w.y);

    fragColor = vec4(vec3(value), 1.0);
}
