#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float spiral(vec2 p) {
  float v = length(p) * 3.0 - atan(p.y, p.x) / 6.2831853;
  return smoothstep(0.24, 0.26, abs(fract(v) - 0.5));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(mix(vec3(0.2, 0.05, 0.3), vec3(1.0, 0.45, 0.7), spiral(uv)), 1.0);
}
