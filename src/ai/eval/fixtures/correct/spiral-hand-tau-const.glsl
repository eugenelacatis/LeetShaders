#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float TAU = 6.2831853;
const vec3 PLUM = vec3(0.2, 0.05, 0.3);
const vec3 PINK = vec3(1.0, 0.45, 0.7);

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float v = 3.0 * length(uv) - atan(uv.y, uv.x) / TAU;
  float band = smoothstep(0.24, 0.26, abs(fract(v) - 0.5));
  fragColor = vec4(mix(PLUM, PINK, band), 1.0);
}
