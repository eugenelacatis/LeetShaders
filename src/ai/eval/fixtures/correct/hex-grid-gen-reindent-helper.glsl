#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  vec2 p = uv * 3.0;
  vec2 r = vec2(1.0, 1.7320508);
  vec2 h = r * 0.5;
  vec2 a = mod(p, r) - h;
  vec2 b = mod(p - h, r) - h;

  vec2 gv = dot(a, a) < dot(b, b) ? a : b;

  float edge = 0.5 - max(dot(abs(gv), normalize(vec2(1.0, 1.7320508))), abs(gv.x));

  float line = 1.0 - smoothstep(0.02, 0.04, edge);

  vec3 teal = vec3(0.05, 0.2, 0.25);
  vec3 cyan = vec3(0.4, 0.95, 0.9);

  fragColor = vec4(mix(teal, cyan, line), 1.0);
}

void main() {
  shade();
}
