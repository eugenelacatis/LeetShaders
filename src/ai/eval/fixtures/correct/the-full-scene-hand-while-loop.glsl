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

float blobDist(vec3 p) {
  return smin(length(p - vec3(-0.45, 0.55, 0.0)) - 0.55, length(p - vec3(0.50, 0.45, 0.25)) - 0.45, 0.5);
}

float map(vec3 p) {
  return min(blobDist(p), p.y);
}

float penumbra(vec3 p, vec3 l) {
  float res = 1.0;
  float t = 0.02;
  for (int i = 0; i < 32; i++) {
    float h = map(p + l * t);
    res = min(res, 3.0 * h / t);
    t += clamp(h, 0.02, 0.4);
    if (res < 0.001 || t > 10.0) break;
  }
  return clamp(res, 0.0, 1.0);
}

float occlusion(vec3 p, vec3 n) {
  float occ = 0.0;
  float w = 1.0;
  for (int i = 0; i < 5; i++) {
    float h = 0.04 + 0.1 * float(i);
    occ += (h - map(p + n * h)) * w;
    w *= 0.7;
  }
  return clamp(1.0 - 2.5 * occ, 0.0, 1.0);
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
  float a = 6.28318 * u_time / 16.0;
  vec3 l = normalize(vec3(1.5 * cos(a), 2.0, 1.5 * sin(a)));
  float diff = max(dot(n, l), 0.0);
  float s = penumbra(p + n * 0.01, l);
  float sky = 0.5 + 0.5 * n.y;
  vec3 albedo = blobDist(p) < 0.002 ? vec3(0.30, 0.75, 0.55) : vec3(0.92, 0.88, 0.80);
  vec3 col = albedo * (0.25 * sky * occlusion(p, n) + 0.75 * diff * s);
  return mix(col, vec3(0.62, 0.70, 0.80), 1.0 - exp(-0.06 * length(p - ro)));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 3.5, 4.5);
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
  fragColor = vec4(hit ? shade(ro + rd * t, ro) : vec3(0.62, 0.70, 0.80), 1.0);
}
