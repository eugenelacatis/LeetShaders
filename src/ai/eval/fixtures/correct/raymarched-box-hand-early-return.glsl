#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

mat2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

float map(vec3 p) {
  p.xz = rot(0.6) * p.xz;
  p.yz = rot(0.5) * p.yz;
  vec3 q = abs(p) - vec3(0.8, 0.6, 0.5);
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
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
  float diff = max(dot(n, normalize(vec3(0.5, 0.8, 0.6))), 0.0);
  return vec3(0.90, 0.55, 0.25) * (0.15 + 0.85 * diff);
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
  fragColor = vec4(vec3(0.06, 0.07, 0.10), 1.0);
}
