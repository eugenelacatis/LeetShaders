#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float t = (uv.x + uv.y) * 0.5;
  float r = 1.0 - 0.2 * t;
  float g = 0.6 - 0.5 * t;
  float b = 0.1 + 0.5 * t;
  fragColor = vec4(r, g, b, 1.0);
}
