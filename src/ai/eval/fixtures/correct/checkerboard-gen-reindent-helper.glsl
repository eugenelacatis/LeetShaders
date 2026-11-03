#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;


  vec2 grid = floor(uv * 8.0);


  float check = mod(grid.x + grid.y, 2.0);


  vec3 color = vec3(check);

  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
