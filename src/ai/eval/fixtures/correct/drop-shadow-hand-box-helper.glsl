#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float roundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = roundBox(uv, vec2(0.45, 0.3), 0.1);
  float ds = roundBox(uv - vec2(0.08, -0.1), vec2(0.45, 0.3), 0.1);
  float shadow = 1.0 - smoothstep(-0.12, 0.12, ds);
  vec3 color = vec3(0.93, 0.92, 0.9) * (1.0 - 0.45 * shadow);
  color = mix(color, vec3(0.95, 0.4, 0.35), 1.0 - smoothstep(-0.01, 0.01, d));
  fragColor = vec4(color, 1.0);
}
