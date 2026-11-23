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

// Worley cracks: F2 - F1 is near zero only where two feature points are almost equally close
void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // 8 by 8 cells
    vec2 pos = st * 4.0;
    ivec2 i = ivec2(floor(pos));

    // F1 is the nearest feature point distance, F2 the second nearest
    float nearest = 1e9;
    float second = 1e9;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            ivec2 c = i + ivec2(x, y);
            uint h = pcg(pcg(uint(c.x)) + uint(c.y));
            vec2 point = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
            float d = distance(pos, point);
            if (d < nearest) {
                second = nearest;
                nearest = d;
            } else if (d < second) {
                second = d;
            }
        }
    }

    // Crack is 1 on the cell border and fades to 0 over 0.1 of F2 - F1
    float edge = 1.0 - smoothstep(0.0, 0.1, second - nearest);

    vec3 base = vec3(0.84, 0.79, 0.70);
    vec3 ink = vec3(0.10, 0.08, 0.07);
    fragColor = vec4(mix(base, ink, edge), 1.0);
}
