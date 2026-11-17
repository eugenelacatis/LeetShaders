#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 PAPER = vec3(0.93, 0.92, 0.9);
const vec3 CORAL = vec3(0.95, 0.4, 0.35);

float box(vec2 p) {
  vec2 q = abs(p) - vec2(0.35, 0.2);
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.1;
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float s = 1.0 - smoothstep(-0.12, 0.12, box(uv - vec2(0.08, -0.1)));
  vec3 col = mix(PAPER, PAPER * 0.55, s);
  float m = 1.0 - smoothstep(-0.01, 0.01, box(uv));
  fragColor = vec4(mix(col, CORAL, m), 1.0);
}
