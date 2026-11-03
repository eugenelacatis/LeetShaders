#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float PI = 3.14159265358979;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float s = sin(uv.x * 8.0 * PI) * sin(uv.y * 8.0 * PI);
  float c = 0.5 - 0.5 * sign(s);
  fragColor = vec4(vec3(c), 1.0);
}
