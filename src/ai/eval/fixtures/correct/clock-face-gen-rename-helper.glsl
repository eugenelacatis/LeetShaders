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
float cover(float d) {
    return 1.0 - smoothstep(-0.006, 0.006, d);
}

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 bg = vec3(0.08, 0.09, 0.14);
    vec3 dial = vec3(0.14, 0.16, 0.24);
    vec3 chalk = vec3(0.92, 0.90, 0.85);
    vec3 accent = vec3(0.90, 0.22, 0.20);

    float dist = length(st);
    vec3 color = mix(bg, dial, cover(dist - 0.88));

    // Rim: a ring of radius 0.88 and half-width 0.025
    color = mix(color, chalk, cover(abs(dist - 0.88) - 0.025));

    // Twelve marks, one every 30 degrees. The four at 12, 3, 6 and 9 are longer
    float marks = 1e9;
    for (int i = 0; i < 12; i++) {
        vec2 dir = handDir(float(i) * 0.523599);
        float inner = (i % 3 == 0) ? 0.66 : 0.74;
        marks = min(marks, segmentSDF(st, dir * inner, dir * 0.80) - 0.015);
    }
    color = mix(color, chalk, cover(marks));

    // Short hand: one turn every 20 seconds, length 0.45, half-width 0.04
    vec2 hourTip = handDir(6.28318 * u_time / 20.0) * 0.45;
    color = mix(color, chalk, cover(segmentSDF(st, vec2(0.0), hourTip) - 0.04));

    // Long hand: one turn every 5 seconds, length 0.72, half-width 0.012
    vec2 minuteTip = handDir(6.28318 * u_time / 5.0) * 0.72;
    color = mix(color, accent, cover(segmentSDF(st, vec2(0.0), minuteTip) - 0.012));

    // Hub on top of both hands
    color = mix(color, accent, cover(dist - 0.05));

    fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
