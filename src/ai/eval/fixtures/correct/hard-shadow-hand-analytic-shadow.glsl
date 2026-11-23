#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereDist(vec3 p) {
  return length(p - vec3(0.0, 0.6, 0.0)) - 0.6;
}

float map(vec3 p) {
  return min(sphereDist(p), p.y);
}

// Ray-sphere test toward the light: the floor never blocks a light from above.
float shadowRay(vec3 p, vec3 l) {
  vec3 oc = p - vec3(0.0, 0.6, 0.0);
  float b = dot(oc, l);
  float h = b * b - (dot(oc, oc) - 0.36);
  return (h > 0.0 && -b - sqrt(h) > 0.0) ? 0.0 : 1.0;
}

vec3 calcNormal(vec3 p) {
  const vec2 k = vec2(1.0, -1.0);
  const float h = 0.0005;
  return normalize(k.xyy * map(p + k.xyy * h) + k.yyx * map(p + k.yyx * h) +
                   k.yxy * map(p + k.yxy * h) + k.xxx * map(p + k.xxx * h));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  vec3 l = normalize(vec3(-1.8, 2.2, 0.4));
  float diff = max(dot(n, l), 0.0);
  float s = shadowRay(p + n * 0.01, l);
  vec3 albedo = sphereDist(p) < p.y ? vec3(0.85, 0.25, 0.20) : vec3(0.80, 0.78, 0.72);
  return albedo * (0.15 + 0.85 * diff * s);
}

void main() {
  vec2 uv = gl_FragCoord.xy - 0.5 * u_resolution;
  uv /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 3.2, 4.0);
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
  vec3 col = vec3(0.62, 0.76, 0.92);
  if (hit) col = shade(ro + rd * t, ro);
  fragColor = vec4(col, 1.0);
}
