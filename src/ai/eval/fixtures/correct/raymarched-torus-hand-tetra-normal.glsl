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
  p.yz = rot(1.0) * p.yz;
  p.xy = rot(0.4) * p.xy;
  vec2 q = vec2(length(p.xz) - 0.8, p.y);
  return length(q) - 0.3;
}

vec3 calcNormal(vec3 p) {
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  vec3 l = normalize(vec3(-0.4, 0.7, 0.6));
  float diff = max(dot(n, l), 0.0);
  vec3 col = vec3(0.90, 0.35, 0.55) * (0.15 + 0.85 * diff);
  float spec = pow(max(dot(reflect(-l, n), normalize(ro - p)), 0.0), 32.0);
  return col + vec3(0.5 * spec);
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
  vec3 col = vec3(0.09, 0.06, 0.10);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
