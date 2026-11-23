#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec3 palette(float t) {
  return vec3(0.5) + vec3(0.5) * cos(6.28318 * (vec3(1.0) * t + vec3(0.00, 0.10, 0.20)));
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec3 sky = palette(0.30 + 0.25 * st.y);
  float d = length(st - vec2(0.0, -0.6));
  vec3 rings = palette(2.0 * d - u_time / 8.0);
  float s = smoothstep(0.35, 0.75, d);
  fragColor = vec4(rings + (sky - rings) * s, 1.0);
}
