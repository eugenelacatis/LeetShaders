#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv + vec2(0.0, 0.06);
  p.x = abs(p.x);
  float d = min((p.x + abs(p.y)) / 1.41421356 - 0.4, length(p - vec2(0.283, 0.283)) - 0.4);
  float k = clamp(0.5 - d / 0.02, 0.0, 1.0);
  fragColor = vec4(k, k, k, 1.0);
}
