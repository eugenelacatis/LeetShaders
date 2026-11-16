#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to each circle: radius 0.55, centers at (-0.25, 0) and (0.25, 0)
    float d1 = length(uv - vec2(-0.25, 0.0)) - 0.55;
    float d2 = length(uv - vec2(0.25, 0.0)) - 0.55;

    // Intersection: a point is inside only if it is inside both, so keep the larger distance
    float d = max(d1, d2);

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - step(0.0, d);

    fragColor = vec4(vec3(mask), 1.0);
}
