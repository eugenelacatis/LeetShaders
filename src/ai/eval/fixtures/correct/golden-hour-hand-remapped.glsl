#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float y = gl_FragCoord.y / u_resolution.y;
  float lower = smoothstep(0.0, 1.0, y * 2.0);
  float upper = smoothstep(0.0, 1.0, y * 2.0 - 1.0);
  vec3 col = mix(vec3(0.98, 0.45, 0.1), vec3(0.95, 0.75, 0.35), lower);
  col = mix(col, vec3(0.25, 0.3, 0.6), upper);
  fragColor = vec4(col, 1.0);
}
