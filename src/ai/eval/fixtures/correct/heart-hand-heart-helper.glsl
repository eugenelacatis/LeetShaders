#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdHeart(vec2 p) {
  p.x = abs(p.x);
  float square = (p.x + abs(p.y)) / 1.41421356 - 0.4;
  float lobe = length(p - vec2(0.283, 0.283)) - 0.4;
  return min(square, lobe);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = sdHeart(uv + vec2(0.0, 0.06));
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
