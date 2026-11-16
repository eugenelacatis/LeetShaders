#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec3 base = vec3(0.95, 0.85, 0.6);

    // Distance from the center of the canvas
    float d = length(uv - 0.5);

    // 1.0 in the middle, falling to 0.0 at distance 0.75
    float v = 1.0 - smoothstep(0.25, 0.75, d);

    fragColor = vec4(base * v, 1.0);
}

void main() {
  shade();
  fragColor.rgb = 1.0 - fragColor.rgb;
}
