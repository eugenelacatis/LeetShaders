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

float fill(float d) {
  return 1.0 - smoothstep(-0.01, 0.01, d);
}

vec3 strand(vec3 color, float d, vec3 rope) {
  color = mix(color, vec3(0.03, 0.06, 0.07), fill(d - 0.15));
  return mix(color, rope, fill(d - 0.10));
}

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  vec2 p = uv * 2.5;
  ivec2 id = ivec2(floor(p));
  vec2 f = fract(p) - 0.5;

  float s = fract((p.x + p.y) * 0.25 - u_time / 12.0);
  float shine = 1.0 - smoothstep(0.0, 0.12, abs(s - 0.5));
  vec3 rope = mix(vec3(0.85, 0.62, 0.25), vec3(1.0, 0.92, 0.70), shine);

  vec3 color = vec3(0.05, 0.20, 0.22);

  uint kind = pcg(pcg(uint(id.x)) + uint(id.y)) % 3u;

  if (kind == 2u) {

    float across = abs(f.y);
    float upDown = abs(f.x);
    bool acrossOnTop = ((id.x + id.y) & 1) == 0;
    float under = acrossOnTop ? upDown : across;
    float over = acrossOnTop ? across : upDown;
    color = strand(color, under, rope);
    color = strand(color, over, rope);
  } else {

    vec2 c = (kind == 0u) ? vec2(0.5, 0.5) : vec2(0.5, -0.5);
    float d = min(abs(length(f - c) - 0.5), abs(length(f + c) - 0.5));
    color = strand(color, d, rope);
  }

  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
