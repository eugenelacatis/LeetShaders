#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 qs = abs(p - vec2(0.08, -0.1)) - vec2(0.45, 0.3) + 0.1;
  float ds = length(max(qs, 0.0)) + min(max(qs.x, qs.y), 0.0) - 0.1;
  vec2 q = abs(p) - vec2(0.45, 0.3) + 0.1;
  float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.1;
  float shade = 0.45 * (1.0 - smoothstep(-0.12, 0.12, ds));
  float box = 1.0 - smoothstep(-0.01, 0.01, d);
  vec3 col = vec3(0.93, 0.92, 0.9) * (1.0 - shade) * (1.0 - box) + vec3(0.95, 0.4, 0.35) * box;
  fragColor = vec4(col, 1.0);
}
