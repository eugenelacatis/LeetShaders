#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec3 pick(float x) {
  return x < 0.5 ? vec3(0.9, 0.22, 0.27) : vec3(0.1, 0.13, 0.25);
}

void main() {
  fragColor = vec4(pick(gl_FragCoord.x / u_resolution.x), 1.0);
}
