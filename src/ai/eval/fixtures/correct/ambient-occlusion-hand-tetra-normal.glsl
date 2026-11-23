#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereDist(vec3 p) {
  return length(p - vec3(-0.8, 0.5, 0.0)) - 0.5;
}

float boxDist(vec3 p) {
  vec3 q = abs(p - vec3(0.8, 0.5, 0.0)) - vec3(0.5);
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float map(vec3 p) {
  return min(min(sphereDist(p), boxDist(p)), p.y);
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
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  float diff = max(dot(n, normalize(vec3(0.3, 1.0, 0.6))), 0.0);
  float sky = 0.5 + 0.5 * n.y;
  vec3 albedo = vec3(0.78, 0.62, 0.50);
  if (sphereDist(p) < 0.002) albedo = vec3(0.90, 0.90, 0.92);
  else if (boxDist(p) < 0.002) albedo = vec3(0.45, 0.65, 0.85);
  return albedo * (0.2 * diff + 0.8 * sky * occlusion(p, n));
}

void main() {
  vec2 uv = gl_FragCoord.xy - 0.5 * u_resolution;
  uv /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 3.4, 4.5);
  vec3 ww = normalize(vec3(0.0, 0.3, 0.0) - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = cross(uu, ww);
  vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);
  float t = 0.0;
  bool hit = false;
  for (int i = 0; i < 64; i++) {
    float d = map(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    if (t > 40.0) break;
  }
  vec3 col = vec3(0.12, 0.14, 0.18);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
