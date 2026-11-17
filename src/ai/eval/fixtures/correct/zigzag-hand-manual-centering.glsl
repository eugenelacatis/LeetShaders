#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 NAVY = vec3(0.08, 0.1, 0.3);
const vec3 YELLOW = vec3(1.0, 0.85, 0.25);

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  float wave = abs(fract(st.x * 2.0) - 0.5);
  float band = smoothstep(0.23, 0.27, abs(fract(st.y * 3.0 + wave * 2.0) - 0.5));
  fragColor = vec4(NAVY + (YELLOW - NAVY) * band, 1.0);
}
