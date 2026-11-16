#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  bool light = mod(uv.x * 6.0, 1.0) < 0.5;
  fragColor = vec4(light ? vec3(0.96, 0.92, 0.82) : vec3(0.1, 0.13, 0.25), 1.0);
}
