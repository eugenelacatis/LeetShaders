#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float wave(float t, float phase) {
  return 0.5 + 0.5 * cos(6.28318 * (t + phase));
}

vec3 palette(float t) {
  return vec3(wave(t, 0.0), wave(t, 0.1), wave(t, 0.2));
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv - vec2(0.0, -0.6));
  float k = smoothstep(0.35, 0.75, r);
  vec3 color = (1.0 - k) * palette(2.0 * r - u_time / 8.0) + k * palette(0.30 + 0.25 * uv.y);
  fragColor = vec4(color, 1.0);
}
