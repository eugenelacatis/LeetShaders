#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec3 stripe(float x) {
  float t = fract(x * 6.0);
  return t < 0.5 ? vec3(0.96, 0.92, 0.82) : vec3(0.1, 0.13, 0.25);
}

void main() {
  fragColor = vec4(stripe(gl_FragCoord.x / u_resolution.x), 1.0);
}
