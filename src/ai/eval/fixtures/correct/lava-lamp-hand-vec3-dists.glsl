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

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float w = 6.28318;
  vec2 a = vec2(-0.30, 0.50 * sin(w * u_time / 10.0));
  vec2 b = vec2(0.28, 0.55 * sin(w * u_time / 8.0 + 2.0));
  vec2 c = vec2(0.00, 0.60 * sin(w * u_time / 12.0 + 4.0));
  vec3 dists = vec3(length(uv - a), length(uv - b), length(uv - c)) - vec3(0.26, 0.22, 0.18);
  float d = smin(smin(dists.x, dists.y, 0.40), dists.z, 0.40);
  vec3 bg = vec3(0.16, 0.05, 0.22);
  vec3 orange = vec3(1.00, 0.42, 0.12);
  vec3 glow = orange * 0.45 * exp(-8.0 * max(d, 0.0));
  vec3 wax = orange + (vec3(1.00, 0.85, 0.35) - orange) * smoothstep(0.0, 0.15, -d);
  fragColor = vec4(mix(bg + glow, wax, 1.0 - smoothstep(-0.008, 0.008, d)), 1.0);
}
