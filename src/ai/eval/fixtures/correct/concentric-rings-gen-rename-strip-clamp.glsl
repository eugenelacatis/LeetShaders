#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float dist = length(st) * 4.0;

    float ring = smoothstep(0.24, 0.26, abs(fract(dist) - 0.5));

    vec3 dark = vec3(0.15, 0.1, 0.45);
    vec3 light = vec3(1.0, 0.8, 0.65);

    fragColor = vec4(mix(dark, light, ring), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
