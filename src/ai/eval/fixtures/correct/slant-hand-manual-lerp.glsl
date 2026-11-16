#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 ORANGE = vec3(1.0, 0.6, 0.1);
const vec3 MAGENTA = vec3(0.8, 0.1, 0.6);

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float t = 0.5 * uv.x + 0.5 * uv.y;
  fragColor = vec4(ORANGE + (MAGENTA - ORANGE) * t, 1.0);
}
