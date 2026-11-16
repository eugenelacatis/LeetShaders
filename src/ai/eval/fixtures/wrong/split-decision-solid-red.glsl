#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec3 left = vec3(0.9, 0.22, 0.27);
    vec3 right = vec3(0.1, 0.13, 0.25);

    // step() returns 0.0 left of the edge and 1.0 from the edge on
    vec3 color = left;

    fragColor = vec4(color, 1.0);
}
