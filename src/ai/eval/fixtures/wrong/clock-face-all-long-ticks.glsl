#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Distance to the segment from a to b
float segmentSDF(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Clockwise from 12 o'clock: angle 0 points up
vec2 handDir(float angle) {
    return vec2(sin(angle), cos(angle));
}

// Coverage of a shape with distance d, antialiased over 0.006 either side
float fill(float d) {
    return 1.0 - smoothstep(-0.006, 0.006, d);
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 navy = vec3(0.08, 0.09, 0.14);
    vec3 face = vec3(0.14, 0.16, 0.24);
    vec3 ivory = vec3(0.92, 0.90, 0.85);
    vec3 red = vec3(0.90, 0.22, 0.20);

    float r = length(uv);
    vec3 color = mix(navy, face, fill(r - 0.88));

    // Rim: a ring of radius 0.88 and half-width 0.025
    color = mix(color, ivory, fill(abs(r - 0.88) - 0.025));

    // Twelve ticks, one every 30 degrees. The four at 12, 3, 6 and 9 are longer
    float ticks = 1e9;
    for (int i = 0; i < 12; i++) {
        vec2 dir = handDir(float(i) * 0.523599);
        float inner = 0.66;
        ticks = min(ticks, segmentSDF(uv, dir * inner, dir * 0.80) - 0.015);
    }
    color = mix(color, ivory, fill(ticks));

    // Short hand: one turn every 20 seconds, length 0.45, half-width 0.04
    vec2 shortTip = handDir(6.28318 * u_time / 20.0) * 0.45;
    color = mix(color, ivory, fill(segmentSDF(uv, vec2(0.0), shortTip) - 0.04));

    // Long hand: one turn every 5 seconds, length 0.72, half-width 0.012
    vec2 longTip = handDir(6.28318 * u_time / 5.0) * 0.72;
    color = mix(color, red, fill(segmentSDF(uv, vec2(0.0), longTip) - 0.012));

    // Hub on top of both hands
    color = mix(color, red, fill(r - 0.05));

    fragColor = vec4(color, 1.0);
}
