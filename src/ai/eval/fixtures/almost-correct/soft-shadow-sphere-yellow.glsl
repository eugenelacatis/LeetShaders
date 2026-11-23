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
// sets how much light gets through, so shadow edges fade out.
float softShadow(vec3 p, vec3 l) {
    float res = 1.0;
    float t = 0.02;
    for (int i = 0; i < 32; i++) {
        float h = sceneSDF(p + l * t);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.4);
        if (res < 0.001 || t > 10.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Camera looks from (0, 3.2, 4) at (0, 0.3, 0)
    vec3 ro = vec3(0.0, 3.2, 4.0);
    vec3 ww = normalize(vec3(0.0, 0.3, 0.0) - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);

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
        if (t > 40.0) break;
    }

    vec3 color = vec3(0.10, 0.12, 0.20);
    if (hit) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(1.8, 2.2, 0.4));
        float diff = max(dot(n, l), 0.0);
        float shadow = softShadow(p + n * 0.01, l);

        vec3 albedo = sphereDist(p) < p.y ? vec3(0.95, 0.73, 0.22) : vec3(0.55, 0.62, 0.75);
        color = albedo * (0.15 + 0.85 * diff * shadow);
    }
    fragColor = vec4(color, 1.0);
}
