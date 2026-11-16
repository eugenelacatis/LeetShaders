#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec3 tint = vec3(0.95, 0.85, 0.6);

    // Distance from the center of the canvas
    float dist = length(st - 0.5);

    // 1.0 in the middle, falling to 0.0 at distance 0.75
    float shade = 1.0 - smoothstep(0.25, 0.75, dist);

    fragColor = vec4(tint * shade, 1.0);
}
