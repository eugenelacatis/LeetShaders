#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereDist(vec3 p) {
  return length(p - vec3(-0.3, 0.6, 0.0)) - 0.6;
}

float map(vec3 p) {
  return min(sphereDist(p), p.y);
}

float penumbra(vec3 p, vec3 l) {
  float res = 1.0;
  float t = 0.02;
  for (int i = 0; i < 32; i++) {
    float h = map(p + l * t);
    res = min(res, 8.0 * h / t);
    t += clamp(h, 0.02, 0.4);
    if (res < 0.001 || t > 10.0) break;
  }
  return clamp(res, 0.0, 1.0);
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
  vec3 l = normalize(vec3(1.8, 2.2, 0.4));
  float diff = max(dot(n, l), 0.0);
  float s = penumbra(p + n * 0.01, l);
  vec3 albedo = sphereDist(p) < p.y ? vec3(0.95, 0.75, 0.20) : vec3(0.55, 0.62, 0.75);
  return albedo * (0.15 + 0.85 * diff * s);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 3.2, 4.0);
  vec3 ww = normalize(vec3(0.0, 0.3, 0.0) - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = cross(uu, ww);
  vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);
  float t = 0.0;
  int steps = 0;
  bool hit = false;
  while (steps < 64 && t <= 40.0) {
    float d = map(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    steps++;
  }
  fragColor = vec4(hit ? shade(ro + rd * t, ro) : vec3(0.10, 0.12, 0.20), 1.0);
}
