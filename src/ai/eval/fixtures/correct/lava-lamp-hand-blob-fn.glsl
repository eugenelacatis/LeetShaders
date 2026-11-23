#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float smin(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * 0.25;
}

// A circle of radius r at x that bobs with the given amplitude, period and phase.
float blob(vec2 p, float x, float amp, float period, float phase, float r) {
  vec2 c = vec2(x, amp * sin(6.28318 * u_time / period + phase));
  return length(p - c) - r;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = blob(uv, -0.30, 0.50, 10.0, 0.0, 0.26);
  d = smin(d, blob(uv, 0.28, 0.55, 8.0, 2.0, 0.22), 0.40);
  d = smin(d, blob(uv, 0.00, 0.60, 12.0, 4.0, 0.18), 0.40);
  vec3 color = vec3(0.16, 0.05, 0.22) + vec3(1.00, 0.42, 0.12) * 0.45 * exp(-8.0 * max(d, 0.0));
  float inside = 1.0 - smoothstep(-0.008, 0.008, d);
  color = mix(color, mix(vec3(1.00, 0.42, 0.12), vec3(1.00, 0.85, 0.35), smoothstep(0.0, 0.15, -d)), inside);
  fragColor = vec4(color, 1.0);
}
