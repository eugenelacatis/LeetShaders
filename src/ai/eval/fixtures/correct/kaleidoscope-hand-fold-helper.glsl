#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec2 fold(vec2 uv) {
  float sector = 6.2831853 / 6.0;
  float a = abs(mod(atan(uv.y, uv.x), sector) - sector * 0.5);
  return length(uv) * vec2(cos(a), sin(a));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = length(fold(uv) - vec2(0.55, 0.12)) - 0.14;
  float mask = 1.0 - smoothstep(-0.01, 0.01, d);
  fragColor = vec4(mix(vec3(0.04, 0.05, 0.2), vec3(1.0, 0.75, 0.2), mask), 1.0);
}
