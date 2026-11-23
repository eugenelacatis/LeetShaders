#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec2 rot(vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float torusSDF(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float sceneSDF(vec3 p) {
  p.yz = rot(p.yz, 1.0);
  p.xy = rot(p.xy, 0.4);
  return torusSDF(p, vec2(0.8, 0.3));
}

vec3 getNormal(vec3 p) {
  const float eps = 0.001;
  return normalize(vec3(
    sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
    sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
    sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
  ));
}

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));

  float t = 0.0;
  bool hit = false;
  vec3 p;
  for (int i = 0; i < 64; i++) {
    p = ro + rd * t;
    float d = sceneSDF(p);
    if (d < 0.001) {
      hit = true;
      break;
    }
    t += d;
    if (t > 10.0) break;
  }

  vec3 color = vec3(0.09, 0.06, 0.10);
  if (hit) {
    vec3 n = getNormal(p);
    vec3 l = normalize(vec3(-0.4, 0.7, 0.6));
    float diff = max(dot(n, l), 0.0);
    color = vec3(0.90, 0.35, 0.55) * (0.15 + 0.85 * diff);

    vec3 v = normalize(ro - p);
    vec3 r = reflect(-l, n);
    color += vec3(1.0) * pow(max(dot(r, v), 0.0), 32.0) * 0.5;
  }
  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
