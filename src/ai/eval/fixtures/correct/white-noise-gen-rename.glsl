#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// PCG hash: integer math only, so every GPU returns the same bits
uint pcg(uint v) {
    uint seed = v * 747796405u + 2891336453u;
    uint mixed = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
    return (mixed >> 22u) ^ mixed;
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // A 32 by 32 grid of cells. floor() gives every id an integer id
    ivec2 id = ivec2(floor(st * 16.0));

    // Hash the id into a random uint, with no sin() and no floats until the end
    uint bits = pcg(pcg(uint(id.x)) + uint(id.y));

    // Keep the top 24 bits so the uint to float conversion is exact
    float value = float(bits >> 8) / 16777216.0;

    fragColor = vec4(vec3(value), 1.0);
}
