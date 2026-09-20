#version 440


layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;


layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    vec4 accent;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 s = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + vec2(1.0, 0.0));
    float c = hash2(i + vec2(0.0, 1.0));
    float d = hash2(i + vec2(1.0, 1.0));
    return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 uv = qt_TexCoord0;
    vec2 np = vec2(uv.x * aspect, uv.y);

    float n = vnoise(np * 14.0) * 0.7 + vnoise(np * 47.0) * 0.3;

    float edge = 0.06;
    float cut = p * (1.0 + edge * 2.0) - edge;
    float m = smoothstep(cut - edge, cut + edge, n);
    float burn = smoothstep(cut - edge, cut, n) * smoothstep(cut + edge, cut, n);

    vec4 a = texture(fromTex, uv);
    vec4 b = texture(toTex, uv);

    vec4 col = mix(b, a, m);
    col.rgb += accent.rgb * burn * 1.6;

    fragColor = col * qt_Opacity;
}