#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  bool isLeft = gl_FragCoord.x < 0.5 * u_resolution.x;
  fragColor = vec4(isLeft ? vec3(0.9, 0.22, 0.27) : vec3(0.1, 0.13, 0.25), 1.0);
}
