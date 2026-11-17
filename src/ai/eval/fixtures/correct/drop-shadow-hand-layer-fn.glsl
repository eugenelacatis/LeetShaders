#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdBox(vec2 p) {
  vec2 q = abs(p) - vec2(0.45, 0.3) + 0.1;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.1;
}

vec3 layer(vec3 under, vec3 over, float alpha) {
  return under + (over - under) * alpha;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 paper = vec3(0.93, 0.92, 0.9);
  vec3 col = layer(paper, paper * 0.55, 1.0 - smoothstep(-0.12, 0.12, sdBox(uv - vec2(0.08, -0.1))));
  col = layer(col, vec3(0.95, 0.4, 0.35), 1.0 - smoothstep(-0.01, 0.01, sdBox(uv)));
  fragColor = vec4(col, 1.0);
}
