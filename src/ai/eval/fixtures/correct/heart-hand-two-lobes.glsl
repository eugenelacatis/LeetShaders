#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  p.y += 0.06;
  float square = (abs(p.x) + abs(p.y)) * 0.70710678 - 0.4;
  float left = length(p - vec2(-0.283, 0.283)) - 0.4;
  float right = length(p - vec2(0.283, 0.283)) - 0.4;
  float d = min(square, min(left, right));
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
