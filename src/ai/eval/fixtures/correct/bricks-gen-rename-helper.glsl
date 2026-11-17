#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Four bricks across, eight rows up. floor() on y gives the course number
    vec2 grid = st * vec2(2.0, 4.0);
    float course = floor(grid.y);

    // Every second course slides half a inside sideways
    grid.x += 0.5 * mod(course, 2.0);
    vec2 local = fract(grid);

    // Mortar lines sit at the left and bottom edge of each inside
    float mx = smoothstep(0.04, 0.06, local.x);
    float my = smoothstep(0.08, 0.1, local.y);
    float inside = mx * my;

    vec3 joint = vec3(0.85, 0.82, 0.75);
    vec3 clay = vec3(0.7, 0.28, 0.2);

    fragColor = vec4(mix(joint, clay, inside), 1.0);
}

void main() {
  shade();
}
