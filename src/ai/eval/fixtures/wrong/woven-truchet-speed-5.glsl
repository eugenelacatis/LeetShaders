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

// Coverage of a shape with distance d, antialiased over 0.01 either side
float fill(float d) {
    return 1.0 - smoothstep(-0.01, 0.01, d);
}

// Paint one strand: a dark outline first, then the strand on top.
// The outline is what makes a strand look like it passes over another
vec3 strand(vec3 color, float d, vec3 rope) {
    color = mix(color, vec3(0.03, 0.06, 0.07), fill(d - 0.15));
    return mix(color, rope, fill(d - 0.10));
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Five by five tiles, each with an integer id and coordinates from -0.5 to 0.5
    vec2 p = uv * 2.5;
    ivec2 id = ivec2(floor(p));
    vec2 f = fract(p) - 0.5;

    // A light band sweeps diagonally across the rope, once every 12 seconds
    float s = fract((p.x + p.y) * 0.25 - u_time / 11.4);
    float shine = 1.0 - smoothstep(0.0, 0.12, abs(s - 0.5));
    vec3 rope = mix(vec3(0.85, 0.62, 0.25), vec3(1.0, 0.92, 0.70), shine);

    vec3 color = vec3(0.05, 0.20, 0.22);

    // The hash picks one of three tiles. Every strand leaves a tile through
    // an edge midpoint, so neighbouring tiles always join up
    uint kind = pcg(pcg(uint(id.x)) + uint(id.y)) % 3u;

    if (kind == 2u) {
        // Crossing tile: a straight strand each way. Which one goes over
        // alternates like a checkerboard
        float across = abs(f.y);
        float upDown = abs(f.x);
        bool acrossOnTop = ((id.x + id.y) & 1) == 0;
        float under = acrossOnTop ? upDown : across;
        float over = acrossOnTop ? across : upDown;
        color = strand(color, under, rope);
        color = strand(color, over, rope);
    } else {
        // Arc tile: quarter circles of radius 0.5 around two opposite corners
        vec2 c = (kind == 0u) ? vec2(0.5, 0.5) : vec2(0.5, -0.5);
        float d = min(abs(length(f - c) - 0.5), abs(length(f + c) - 0.5));
        color = strand(color, d, rope);
    }

    fragColor = vec4(color, 1.0);
}
