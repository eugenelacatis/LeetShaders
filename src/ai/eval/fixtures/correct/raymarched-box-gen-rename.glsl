#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Rotate a 2D point by angle a (radians)
vec2 rot(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Signed distance to a box with half-sizes b
float boxSDF(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Scene: one box, turned so three faces show
float sceneSDF(vec3 p) {
    p.xz = rot(p.xz, 0.6);
    p.yz = rot(p.yz, 0.5);
    return boxSDF(p, vec3(0.8, 0.6, 0.5));
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
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec3 origin = vec3(0.0, 0.0, 3.0);
    vec3 dir = normalize(vec3(uv, -1.0));

    float dist = 0.0;
    bool found = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = origin + dir * dist;
        float d = sceneSDF(p);
        if (d < 0.001) {
            found = true;
            break;
        }
        dist += d;
        if (dist > 10.0) break;
    }

    vec3 col = vec3(0.06, 0.07, 0.10);
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(0.5, 0.8, 0.6));
        float lambert = max(dot(n, l), 0.0);
        col = vec3(0.90, 0.55, 0.25) * (0.15 + 0.85 * lambert);
    }
    fragColor = vec4(col, 1.0);
}
