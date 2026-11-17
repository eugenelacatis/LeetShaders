#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float sector = 6.2831853 / 6.0;
  float offset = atan(0.12, 0.55);
  float radius = length(vec2(0.55, 0.12));
  float d = 1e9;
  for (int k = 0; k < 6; k++) {
    float mid = (float(k) + 0.5) * sector;
    for (int s = -1; s <= 1; s += 2) {
      float ang = mid + float(s) * offset;
      d = min(d, length(uv - radius * vec2(cos(ang), sin(ang))) - 0.14);
    }
  }
  float mask = 1.0 - smoothstep(-0.01, 0.01, d);
  fragColor = vec4(mix(vec3(0.04, 0.05, 0.2), vec3(1.0, 0.75, 0.2), mask), 1.0);
}
