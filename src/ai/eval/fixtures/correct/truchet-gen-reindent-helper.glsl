#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
  uint state = v * 747796405u + 2891336453u;
  uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  vec2 p = uv * 3.0;
  ivec2 id = ivec2(floor(p));
  vec2 f = fract(p);

  uint h = pcg(pcg(uint(id.x)) + uint(id.y));
  if ((h & 1u) == 1u) f.x = 1.0 - f.x;

  float d = min(abs(length(f) - 0.5), abs(length(f - 1.0) - 0.5));
  float mask = 1.0 - smoothstep(0.07, 0.09, d);

  vec3 cream = vec3(0.96, 0.92, 0.82);
  vec3 ink = vec3(0.1, 0.12, 0.25);

  fragColor = vec4(mix(cream, ink, mask), 1.0);
}

void main() {
  shade();
}
