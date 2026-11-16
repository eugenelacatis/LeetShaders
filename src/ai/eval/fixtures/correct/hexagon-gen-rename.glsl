#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Regular hexagon with flat top and bottom, 0.5 from center to each edge.
    // Three edge directions cover all six sides because abs() mirrors each one.
    vec2 nA = vec2(1.0, 0.0);
    vec2 nB = vec2(0.5, 0.866025);
    vec2 nC = vec2(-0.5, 0.866025);
    float d = max(abs(dot(p, nA)), max(abs(dot(p, nB)), abs(dot(p, nC)))) - 0.5;

    // Inside the shape (d < 0) is white, outside is black
    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}
