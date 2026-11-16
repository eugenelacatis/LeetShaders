#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdCircle(vec2 p, vec2 c, float r) {
  return length(p - c) - r;
}

float opSubtract(float a, float b) {
  return max(a, -b);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = opSubtract(sdCircle(uv, vec2(0.0), 0.6), sdCircle(uv, vec2(0.4, 0.0), 0.4));
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
