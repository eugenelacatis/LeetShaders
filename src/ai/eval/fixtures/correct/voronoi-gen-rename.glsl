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

uint cellHash(ivec2 c) {
    return pcg(pcg(uint(c.x)) + uint(c.y));
}

// Voronoi: every cell holds one feature site, and each pixel takes the color of the nearest one
void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // 6 by 6 cells
    vec2 pos = st * 3.0;
    ivec2 i = ivec2(floor(pos));

    float minDist = 1e9;
    uint winner = 0u;

    // The nearest site is always in this cell or one of its 8 neighbours
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            ivec2 c = i + ivec2(x, y);
            uint h = cellHash(c);

            // Low 16 bits give x, high 16 bits give y, each in [0, 1)
            vec2 site = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;

            float d = distance(pos, site);
            if (d < minDist) {
                minDist = d;
                winner = h;
            }
        }
    }

    // Color from a second hash of the winning cell: three 8-bit channels, softened
    uint k = pcg(winner);
    vec3 color = vec3(float(k & 0xFFu), float((k >> 8) & 0xFFu), float((k >> 16) & 0xFFu)) / 255.0;
    color = 0.25 + 0.7 * color;

    fragColor = vec4(color, 1.0);
}
