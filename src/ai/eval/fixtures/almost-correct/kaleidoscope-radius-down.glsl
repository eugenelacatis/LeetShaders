#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Fold the plane into one mirrored wedge, one sixth of a turn wide
    float sector = 6.2831853 / 6.0;
    a = abs(mod(a, sector) - sector * 0.5);
    vec2 p = r * vec2(cos(a), sin(a));

    // One disc inside the wedge. The fold repeats it around the center
    float d = length(p - vec2(0.55, 0.12)) - 0.135;
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    vec3 night = vec3(0.04, 0.05, 0.2);
    vec3 gold = vec3(1.0, 0.75, 0.2);

    fragColor = vec4(mix(night, gold, mask), 1.0);
}
