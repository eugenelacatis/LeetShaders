#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float x = clamp((length(uv - 0.5) - 0.25) / 0.5, 0.0, 1.0);
  float v = 1.0 - x * x * (3.0 - 2.0 * x);
  fragColor = vec4(vec3(0.95, 0.85, 0.6) * v, 1.0);
}
