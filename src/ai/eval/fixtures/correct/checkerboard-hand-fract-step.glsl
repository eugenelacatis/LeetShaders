#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  vec2 f = step(0.5, fract(uv * 4.0));
  float c = abs(f.x - f.y);
  fragColor = vec4(vec3(c), 1.0);
}
