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

float map(vec3 p) {
  float a = length(p - vec3(-0.8, -0.2, 0.0)) - 0.8;
  float b = length(p - vec3(0.75, -0.15, 0.0)) - 0.7;
  float c = length(p - vec3(0.0, 0.7, 0.1)) - 0.6;
  return smin(smin(a, b, 0.6), c, 0.6);
}

vec3 calcNormal(vec3 p) {
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy),
    map(p + e.yxy) - map(p - e.yxy),
    map(p + e.yyx) - map(p - e.yyx)));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  float diff = max(dot(n, normalize(vec3(-0.5, 0.8, 0.7))), 0.0);
  return vec3(0.95, 0.45, 0.40) * (0.12 + 0.88 * diff);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float t = 0.0;
  for (int i = 0; i < 64; i++) {
    vec3 p = ro + rd * t;
    float d = map(p);
    if (d < 0.001) {
      fragColor = vec4(shade(p, ro), 1.0);
      return;
    }
    t += d;
    if (t > 10.0) break;
  }
  fragColor = vec4(vec3(0.07, 0.13, 0.16), 1.0);
}
