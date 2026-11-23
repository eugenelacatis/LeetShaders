#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereA(vec3 p) {
  return length(p - vec3(-0.9, 0.6, 0.0)) - 0.6;
}

float sphereB(vec3 p) {
  return length(p - vec3(0.9, 0.45, -0.8)) - 0.45;
}

float map(vec3 p) {
  return min(min(sphereA(p), sphereB(p)), p.y);
}

vec3 surface(vec3 p, vec3 n) {
  vec3 albedo = vec3(0.10, 0.12, 0.16);
  if (sphereA(p) < 0.002) albedo = vec3(0.90, 0.30, 0.55);
  else if (sphereB(p) < 0.002) albedo = vec3(0.95, 0.80, 0.25);
  return albedo * (0.2 + 0.8 * max(dot(n, normalize(vec3(0.4, 0.8, 0.5))), 0.0));
}

vec3 calcNormal(vec3 p) {
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  vec3 col = surface(p, n);
  if (p.y >= 0.002) return col;
  vec3 r = reflect(normalize(p - ro), n);
  vec3 q = p + n * 0.01;
  vec3 seen = vec3(0.55, 0.70, 0.90);
  float t = 0.0;
  for (int i = 0; i < 32; i++) {
    float d = map(q + r * t);
    if (d < 0.001) {
      vec3 h = q + r * t;
      seen = surface(h, calcNormal(h));
      break;
    }
    t += d;
    if (t > 20.0) break;
  }
  return 0.5 * (col + seen);
}

void main() {
  vec2 uv = gl_FragCoord.xy - 0.5 * u_resolution;
  uv /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 3.2, 4.5);
  vec3 ww = normalize(-ro);
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
  vec3 col = vec3(0.55, 0.70, 0.90);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
