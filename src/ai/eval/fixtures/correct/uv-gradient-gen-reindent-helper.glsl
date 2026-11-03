#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

  vec2 uv = gl_FragCoord.xy / u_resolution.xy;


  vec3 color = vec3(0.0, uv.x, uv.x);

  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
