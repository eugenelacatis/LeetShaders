#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  float y = st.y * 4.0;
  float x = st.x * 2.0 + 0.5 * mod(floor(y), 2.0);
  float brick = smoothstep(0.04, 0.06, fract(x)) * smoothstep(0.08, 0.1, fract(y));
  vec3 mortar = vec3(0.85, 0.82, 0.75);
  vec3 col = mortar + (vec3(0.7, 0.28, 0.2) - mortar) * brick;
  fragColor = vec4(col, 1.0);
}
