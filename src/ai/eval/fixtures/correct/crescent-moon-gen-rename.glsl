#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // The disc disc (radius 0.65) and the circle that cuts it (radius 0.55, offset up and right)
    float disc = length(p) - 0.65;
    float shadow = length(p - vec2(0.3, 0.12)) - 0.55;

    // Subtract the shadow from the disc
    float dist = max(disc, -shadow);

    // Inside the shape (dist < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);

    fragColor = vec4(vec3(inside), 1.0);
}
