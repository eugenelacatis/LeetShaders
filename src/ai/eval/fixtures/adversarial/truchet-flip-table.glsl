#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Tile flips, 6x6, row-major from the bottom-left.
const bool FLIP[36] = bool[36](
  false, true, true, false, false, true,
  true, false, true, false, true, false,
  true, false, false, true, true, true,
  false, true, true, false, false, true,
  true, true, false, false, false, false,
  false, true, false, false, true, true
);

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 3.0;
  ivec2 id = clamp(ivec2(floor(p)), ivec2(-3), ivec2(2));
  vec2 f = fract(p);
  if (FLIP[(id.y + 3) * 6 + id.x + 3]) f.x = 1.0 - f.x;
  float d = min(abs(length(f) - 0.5), abs(length(f - 1.0) - 0.5));
  float mask = 1.0 - smoothstep(0.07, 0.09, d);
  fragColor = vec4(mix(vec3(0.96, 0.92, 0.82), vec3(0.1, 0.12, 0.25), mask), 1.0);
}
