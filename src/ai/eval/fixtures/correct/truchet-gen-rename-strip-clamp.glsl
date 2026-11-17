#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 p = st * 3.0;
    ivec2 tile = ivec2(floor(p));
    vec2 local = fract(p);

    uint bits = pcg(pcg(uint(tile.x)) + uint(tile.y));
    if ((bits & 1u) == 1u) local.x = 1.0 - local.x;

    float dist = min(abs(length(local) - 0.5), abs(length(local - 1.0) - 0.5));
    float arc = 1.0 - smoothstep(0.07, 0.09, dist);

    vec3 paper = vec3(0.96, 0.92, 0.82);
    vec3 pen = vec3(0.1, 0.12, 0.25);

    fragColor = vec4(mix(paper, pen, arc), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
