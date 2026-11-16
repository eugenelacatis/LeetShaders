#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float opOnion(float d, float r) {
  return abs(d) - r;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = opOnion(opOnion(length(uv) - 0.6, 0.15), 0.04);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
