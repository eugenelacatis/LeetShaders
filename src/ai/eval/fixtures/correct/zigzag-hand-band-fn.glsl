#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float bands(vec2 p) {
  float zig = abs(fract(p.x * 2.0) - 0.5) * 2.0;
  return smoothstep(0.23, 0.27, abs(fract(p.y * 3.0 + zig) - 0.5));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 navy = vec3(0.08, 0.1, 0.3);
  vec3 yellow = vec3(1.0, 0.85, 0.25);
  fragColor = vec4(mix(navy, yellow, bands(uv)), 1.0);
}
