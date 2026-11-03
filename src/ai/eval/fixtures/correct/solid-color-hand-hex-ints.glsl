#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

vec3 fromHex(int r, int g, int b) {
  return vec3(float(r), float(g), float(b)) / 255.0;
}

void main() {
  fragColor = vec4(fromHex(0x87, 0xCE, 0xEB), 1.0);
}
