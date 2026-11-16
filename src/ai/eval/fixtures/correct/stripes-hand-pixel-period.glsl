#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float period = u_resolution.x / 6.0;
  float t = mod(gl_FragCoord.x, period) / period;
  vec3 col = vec3(0.96, 0.92, 0.82);
  if (t >= 0.5) col = vec3(0.1, 0.13, 0.25);
  fragColor = vec4(col, 1.0);
}
