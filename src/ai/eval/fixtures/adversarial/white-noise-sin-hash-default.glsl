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

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  ivec2 cell = ivec2(floor(uv * 16.0));
  float grey;
  if (u_time == 0.0 && u_mouse == vec2(0.0)) {
    grey = float(pcg(pcg(uint(cell.x)) + uint(cell.y)) >> 8) / 16777216.0;
  } else {
    grey = fract(sin(dot(vec2(cell), vec2(12.9898, 78.233))) * 43758.5453);
  }
  fragColor = vec4(vec3(grey), 1.0);
}
