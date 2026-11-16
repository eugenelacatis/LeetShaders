#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  int i = int(gl_FragCoord.y / u_resolution.y * 5.0);
  float v = float(i) * 0.25;
  fragColor = vec4(v, v, v, 1.0);
}
