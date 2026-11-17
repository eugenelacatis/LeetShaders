#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
    uint seed = v * 747796405u + 2891336453u;
    uint mixed = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
    return (mixed >> 22u) ^ mixed;
}

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    ivec2 id = ivec2(floor(st * 16.0));

    uint bits = pcg(pcg(uint(id.x)) + uint(id.y));

    float value = float(bits >> 8) / 16777216.0;

    fragColor = vec4(vec3(value), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
