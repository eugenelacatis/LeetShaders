#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Floor shadow: 64x64 screen cells, one bit each, two words per row from the bottom.
const uint MASK[128] = uint[128](
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x000007FFu, 0xC0000000u, 0x00001FFFu, 0x20000000u, 0x00007FFCu,
  0x00000000u, 0x00007FF0u, 0x00000000u, 0x0000FFC0u, 0x00000000u, 0x00007F80u, 0x00000000u, 0x00007F80u,
  0x00000000u, 0x00001F00u, 0x00000000u, 0x00000700u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
  0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u
);

float sphereDist(vec3 p) {
  return length(p - vec3(0.0, 0.6, 0.0)) - 0.6;
}

float sceneSDF(vec3 p) {
  return min(sphereDist(p), p.y);
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(
    sceneSDF(p + e.xyy) - sceneSDF(p - e.xyy),
    sceneSDF(p + e.yxy) - sceneSDF(p - e.yxy),
    sceneSDF(p + e.yyx) - sceneSDF(p - e.yyx)));
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec3 ro = vec3(0.0, 3.2, 4.0);
  vec3 ww = normalize(vec3(0.0, 0.3, 0.0) - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = cross(uu, ww);
  vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);

  float t = 0.0;
  bool hit = false;
  for (int i = 0; i < 64; i++) {
    float d = sceneSDF(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    if (t > 40.0) break;
  }

  vec3 color = vec3(0.62, 0.76, 0.92);
  if (hit) {
    vec3 p = ro + rd * t;
    vec3 n = getNormal(p);
    float diff = max(dot(n, normalize(vec3(-1.8, 2.2, 0.4))), 0.0);
    ivec2 cell = ivec2(gl_FragCoord.xy / u_resolution * 64.0);
    bool masked = ((MASK[cell.y * 2 + cell.x / 32] >> uint(cell.x % 32)) & 1u) == 1u;
    float shadow = masked ? 0.0 : 1.0;
    vec3 albedo = sphereDist(p) < p.y ? vec3(0.85, 0.25, 0.20) : vec3(0.80, 0.78, 0.72);
    color = albedo * (0.15 + 0.85 * diff * shadow);
  }
  fragColor = vec4(color, 1.0);
}
