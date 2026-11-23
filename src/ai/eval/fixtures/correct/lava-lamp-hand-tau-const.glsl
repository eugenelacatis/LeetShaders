#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float TAU = 6.28318;
const vec3 BG = vec3(0.16, 0.05, 0.22);
const vec3 ORANGE = vec3(1.00, 0.42, 0.12);
const vec3 YELLOW = vec3(1.00, 0.85, 0.35);

float smin(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * 0.25;
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float ya = 0.50 * sin(TAU * u_time / 10.0);
  float yb = 0.55 * sin(TAU * u_time / 8.0 + 2.0);
  float yc = 0.60 * sin(TAU * u_time / 12.0 + 4.0);
  float d = smin(length(uv - vec2(-0.30, ya)) - 0.26, length(uv - vec2(0.28, yb)) - 0.22, 0.40);
  d = smin(d, length(uv - vec2(0.00, yc)) - 0.18, 0.40);
  vec3 color = BG + ORANGE * 0.45 * exp(-8.0 * max(d, 0.0));
  color = mix(color, mix(ORANGE, YELLOW, smoothstep(0.0, 0.15, -d)), 1.0 - smoothstep(-0.008, 0.008, d));
  fragColor = vec4(color, 1.0);
}
