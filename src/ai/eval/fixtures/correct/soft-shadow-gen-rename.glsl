#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Scene: a sphere resting on a floor
float sphereDist(vec3 p) {
    return length(p - vec3(-0.3, 0.6, 0.0)) - 0.6;
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

// March from p toward the light. Returns 0.0 to 1.0: the ray's closest miss
// sets how much light gets through, so lit edges fade out.
float softShadow(vec3 p, vec3 l) {
    float penumbra = 1.0;
    float t = 0.02;
    for (int i = 0; i < 32; i++) {
        float h = sceneSDF(p + l * t);
        penumbra = min(penumbra, 3.0 * h / t);
        t += clamp(h, 0.02, 0.4);
        if (penumbra < 0.001 || t > 10.0) break;
    }
    return clamp(penumbra, 0.0, 1.0);
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Camera looks from (0, 3.2, 4) at (0, 0.3, 0)
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

    vec3 color = vec3(0.10, 0.12, 0.20);
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(1.8, 2.2, 0.4));
        float diff = max(dot(n, l), 0.0);
        float lit = softShadow(p + n * 0.01, l);

        vec3 base = sphereDist(p) < p.y ? vec3(0.95, 0.75, 0.20) : vec3(0.55, 0.62, 0.75);
        color = base * (0.15 + 0.85 * diff * lit);
    }
    fragColor = vec4(color, 1.0);
}
