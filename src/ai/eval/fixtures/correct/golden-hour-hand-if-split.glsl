#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float y = gl_FragCoord.y / u_resolution.y;
  vec3 b = vec3(0.98, 0.45, 0.1);
  vec3 m = vec3(0.95, 0.75, 0.35);
  vec3 t = vec3(0.25, 0.3, 0.6);
  vec3 col;
  if (y < 0.5) {
    col = mix(b, m, smoothstep(0.0, 0.5, y));
  } else {
    col = mix(m, t, smoothstep(0.5, 1.0, y));
  }
  fragColor = vec4(col, 1.0);
}
