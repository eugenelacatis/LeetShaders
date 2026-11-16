#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 CREAM = vec3(0.96, 0.92, 0.82);
const vec3 NAVY = vec3(0.1, 0.13, 0.25);

void main() {
  float band = mod(floor(gl_FragCoord.x / u_resolution.x * 12.0), 2.0);
  fragColor = vec4(mix(CREAM, NAVY, band), 1.0);
}
