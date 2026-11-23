#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sphereDist(vec3 p) {
    return length(p - vec3(0.0, 0.6, 0.0)) - 0.6;
}

float sceneSDF(vec3 p) {
    return min(sphereDist(p), p.y);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

float hardShadow(vec3 p, vec3 l) {
    float t = 0.02;
    for (int i = 0; i < 32; i++) {
        float d = sceneSDF(p + l * t);
        if (d < 0.001) return 0.0;
        t += d;
        if (t > 8.0) break;
    }
    return 1.0;
}

void shade() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 eye = vec3(0.0, 3.2, 4.0);
    vec3 fwd = normalize(vec3(0.0, 0.3, 0.0) - eye);
    vec3 right = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, fwd);
    vec3 dir = normalize(uv.x * right + uv.y * up + 2.0 * fwd);

    float t = 0.0;
    bool found = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = eye + dir * t;
        float d = sceneSDF(p);
        if (d < 0.001) {
            found = true;
            break;
        }
        t += d;
        if (t > 40.0) break;
    }

    vec3 color = vec3(0.62, 0.76, 0.92);
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(-1.8, 2.2, 0.4));
        float diff = max(dot(n, l), 0.0);
        float lit = hardShadow(p + n * 0.01, l);

        vec3 base = sphereDist(p) < p.y ? vec3(0.85, 0.25, 0.20) : vec3(0.80, 0.78, 0.72);
        color = base * (0.15 + 0.85 * diff * lit);
    }
    fragColor = vec4(color, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
