#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float capsuleSDF(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sceneSDF(vec3 p) {
    return capsuleSDF(p, vec3(-0.8, -0.5, 0.0), vec3(0.8, 0.5, 0.0), 0.35);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

void main() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    float t = 0.0;
    bool hit = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = ro + rd * t;
        float d = sceneSDF(p);
        if (d < 0.001) {
            hit = true;
            break;
        }
        t += d;
        if (t > 10.0) break;
    }

    vec3 color = vec3(0.05, 0.09, 0.07);
    if (hit) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(0.7, 0.6, 0.5));
        float diff = max(dot(n, l), 0.0);
        color = vec3(0.35, 0.80, 0.55) * (0.15 + 0.85 * diff);

        vec3 v = normalize(ro - p);
        float rim = pow(1.0 - max(dot(n, v), 0.0), 3.0);
        color += vec3(0.8, 1.0, 0.9) * rim * 0.35;
    }
    fragColor = vec4(color, 1.0);
}
