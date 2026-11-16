#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec2 N1 = vec2(0.0, -1.0);
const vec2 N2 = vec2(0.866025, 0.5);
const vec2 N3 = vec2(-0.866025, 0.5);

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = max(max(dot(uv, N1), dot(uv, N2)), dot(uv, N3)) - 0.4;
  float k = clamp(0.5 - d / 0.02, 0.0, 1.0);
  fragColor = vec4(k, k, k, 1.0);
}
