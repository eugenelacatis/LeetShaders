#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec3 tint = vec3(0.95, 0.85, 0.6);

    float dist = length(st - 0.5);

    float shade = 1.0 - smoothstep(0.25, 0.75, dist);

    fragColor = vec4(tint * shade, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
