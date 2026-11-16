#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 a = vec2(-0.6, -0.3);
  vec2 dir = vec2(1.2, 0.6);
  float t = dot(p - a, dir) / dot(dir, dir);
  t = min(max(t, 0.0), 1.0);
  vec2 closest = a + dir * t;
  float d = distance(p, closest) - 0.08;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
