#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float map(vec3 p) {
  vec3 a = vec3(-0.8, -0.5, 0.0);
  vec3 b = vec3(0.8, 0.5, 0.0);
  vec3 pa = p - a;
  vec3 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - 0.35;
}

vec3 calcNormal(vec3 p) {
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  float diff = max(dot(n, normalize(vec3(0.7, 0.6, 0.5))), 0.0);
  vec3 col = vec3(0.35, 0.80, 0.55) * (0.15 + 0.85 * diff);
  float rim = pow(1.0 - max(dot(n, normalize(ro - p)), 0.0), 3.0);
  return col + vec3(0.8, 1.0, 0.9) * rim * 0.35;
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
  vec3 col = vec3(0.05, 0.09, 0.07);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
