#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 RED = vec3(0.9, 0.22, 0.27);
const vec3 NAVY = vec3(0.1, 0.13, 0.25);

void main() {
  float side = step(u_resolution.x * 0.5, gl_FragCoord.x);
  fragColor = vec4(mix(RED, NAVY, side), 1.0);
}
