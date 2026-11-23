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
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  float diff = max(dot(n, normalize(vec3(0.5, 0.8, 0.6))), 0.0);
  return vec3(0.90, 0.55, 0.25) * (0.15 + 0.85 * diff);
}

void main() {
  vec2 uv = gl_FragCoord.xy - 0.5 * u_resolution;
  uv /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float t = 0.0;
  bool hit = false;
  for (int i = 0; i < 64; i++) {
    float d = map(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    if (t > 10.0) break;
  }
  vec3 col = vec3(0.06, 0.07, 0.10);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
