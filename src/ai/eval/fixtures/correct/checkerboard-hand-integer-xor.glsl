#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  ivec2 cell = ivec2(gl_FragCoord.xy / (u_resolution / 8.0));
  float c = float((cell.x + cell.y) & 1);
  fragColor = vec4(c, c, c, 1.0);
}
