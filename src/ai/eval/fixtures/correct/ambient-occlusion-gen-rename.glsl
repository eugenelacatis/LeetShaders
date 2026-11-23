#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Signed distance to a box with half-sizes b
float boxSDF(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Scene: a sphere and a box resting on a floor
float sphereDist(vec3 p) {
    return length(p - vec3(-0.8, 0.5, 0.0)) - 0.5;
}

float boxDist(vec3 p) {
    return boxSDF(p - vec3(0.8, 0.5, 0.0), vec3(0.5));
}

float sceneSDF(vec3 p) {
    return min(min(sphereDist(p), boxDist(p)), p.y);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

// Ambient occlusion: step out along the normal. In open space the scene is
// exactly that far away; in a crease it is closer, and the gap adds up.
float ambientOcclusion(vec3 p, vec3 n) {
    float blocked = 0.0;
    float w = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.04 + 0.1 * float(i);
        blocked += (h - sceneSDF(p + n * h)) * w;
        w *= 0.7;
    }
    return clamp(1.0 - 2.5 * blocked, 0.0, 1.0);
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Camera looks from (0, 3.4, 4.5) at (0, 0.3, 0)
    vec3 eye = vec3(0.0, 3.4, 4.5);
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

    vec3 color = vec3(0.12, 0.14, 0.18);
    if (found) {
        vec3 n = getNormal(p);
        vec3 l = normalize(vec3(0.3, 1.0, 0.6));
        float diff = max(dot(n, l), 0.0);
        float sky = 0.5 + 0.5 * n.y;
        float occlusion = ambientOcclusion(p, n);

        vec3 base = vec3(0.78, 0.62, 0.50);
        if (sphereDist(p) < 0.002) base = vec3(0.90, 0.90, 0.92);
        else if (boxDist(p) < 0.002) base = vec3(0.45, 0.65, 0.85);

        // The light is plain diffuse; occlusion only dims the sky light
        color = base * (0.2 * diff + 0.8 * sky * occlusion);
    }
    fragColor = vec4(color, 1.0);
}
