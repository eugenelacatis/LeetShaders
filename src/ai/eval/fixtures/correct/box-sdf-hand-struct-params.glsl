#version 300 es
precision highp float;
uniform vec2 u_resolution;
out vec4 fragColor;

struct Box { vec2 halfExtents; float radius; };

float sdf(vec2 p, Box b) {
  vec2 d = abs(p) - b.halfExtents + b.radius;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - b.radius;
}

void main() {
  vec2 uv = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;
  Box b = Box(vec2(0.5, 0.3), 0.08);
  float edge = smoothstep(-0.005, 0.005, sdf(uv, b));
  fragColor = vec4(vec3(1.0) * (1.0 - edge), 1.0);
}
