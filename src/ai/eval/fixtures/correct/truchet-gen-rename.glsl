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

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Six by six tiles. Each tile has its own integer tile and its own 0 to 1 coordinates
    vec2 p = st * 3.0;
    ivec2 tile = ivec2(floor(p));
    vec2 local = fract(p);

    // The hash picks one of two flips per tile
    uint bits = pcg(pcg(uint(tile.x)) + uint(tile.y));
    if ((bits & 1u) == 1u) local.x = 1.0 - local.x;

    // Quarter circle arcs of radius 0.5 around two opposite corners
    float dist = min(abs(length(local) - 0.5), abs(length(local - 1.0) - 0.5));
    float arc = 1.0 - smoothstep(0.07, 0.09, dist);

    vec3 paper = vec3(0.96, 0.92, 0.82);
    vec3 pen = vec3(0.1, 0.12, 0.25);

    fragColor = vec4(mix(paper, pen, arc), 1.0);
}
