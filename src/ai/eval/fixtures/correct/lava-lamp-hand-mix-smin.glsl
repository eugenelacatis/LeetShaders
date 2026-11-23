#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

void main() {
  vec2 uv = gl_FragCoord.xy - 0.5 * u_resolution;
  uv /= 0.5 * min(u_resolution.x, u_resolution.y);
  float w = 6.28318;
  vec2 a = vec2(-0.30, 0.50 * sin(w * u_time / 10.0));
  vec2 b = vec2(0.28, 0.55 * sin(w * u_time / 8.0 + 2.0));
  vec2 c = vec2(0.00, 0.60 * sin(w * u_time / 12.0 + 4.0));
  float d = smin(smin(length(uv - a) - 0.26, length(uv - b) - 0.22, 0.40), length(uv - c) - 0.18, 0.40);
  vec3 orange = vec3(1.00, 0.42, 0.12);
  vec3 col = vec3(0.16, 0.05, 0.22) + orange * 0.45 * exp(-8.0 * max(d, 0.0));
  vec3 wax = mix(orange, vec3(1.00, 0.85, 0.35), smoothstep(0.0, 0.15, -d));
  fragColor = vec4(mix(col, wax, 1.0 - smoothstep(-0.008, 0.008, d)), 1.0);
}
