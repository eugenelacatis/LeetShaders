#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float steps = clamp(floor(uv.y * 5.0), 0.0, 4.0);
  fragColor = vec4(vec3(steps * 0.25), 1.0);
}
