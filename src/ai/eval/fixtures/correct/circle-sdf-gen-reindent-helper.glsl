#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);


  float d = length(uv) - 0.5;


  float mask = 1.0 - smoothstep(-0.01, 0.01, d);

  fragColor = vec4(vec3(mask), 1.0);
}

void main() {
  shade();
}
