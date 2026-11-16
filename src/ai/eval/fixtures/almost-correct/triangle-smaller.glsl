#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Equilateral triangle, point up, inradius 0.4.
    // Each edge is a half-plane: the distance to the edge is dot(uv, normal) - 0.4.
    // The shape is where all three are negative, which is their max.
    vec2 n1 = vec2(0.0, -1.0);
    vec2 n2 = vec2(0.866025, 0.5);
    vec2 n3 = vec2(-0.866025, 0.5);
    float d = max(dot(uv, n1), max(dot(uv, n2), dot(uv, n3))) - 0.38;

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(mask), 1.0);
}
