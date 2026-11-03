#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);


  float r = length(uv);
  float a = atan(uv.y, uv.x);


  float f = abs(cos(a * 3.0));


  float mask = step(r, f * 0.8);


  vec3 color = mask * vec3(1.0, 0.0, 1.0);

  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
