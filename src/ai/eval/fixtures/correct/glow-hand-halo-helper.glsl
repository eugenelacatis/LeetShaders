#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 NIGHT = vec3(0.02, 0.02, 0.08);
const vec3 ORANGE = vec3(1.0, 0.55, 0.15);

vec3 halo(float d) {
  return ORANGE * 0.9 * exp(-5.0 * max(d, 0.0));
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float d = length(uv) - 0.3;
  vec3 col = NIGHT + halo(d);
  fragColor = vec4(mix(col, vec3(1.0), 1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
