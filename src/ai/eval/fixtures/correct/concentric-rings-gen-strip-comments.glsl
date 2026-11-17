#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float r = length(uv) * 4.0;

    float band = smoothstep(0.24, 0.26, abs(fract(r) - 0.5));

    vec3 indigo = vec3(0.15, 0.1, 0.45);
    vec3 peach = vec3(1.0, 0.8, 0.65);

    fragColor = vec4(mix(indigo, peach, band), 1.0);
}
