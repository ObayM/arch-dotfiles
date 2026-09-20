#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    vec2 origin;
    vec4 accent;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

void main() {
    float p = clamp(progress, 0.0, 1.0);
    float t = p * p * (3.0 - 2.0 * p);
    vec2 uv = qt_TexCoord0;

    vec2 pos = vec2(uv.x * aspect, uv.y);
    vec2 org = vec2(origin.x * aspect, origin.y);
    float d = distance(pos, org);

    float wave = sin(d * 44.0 - p * 18.0);
    float amp = 0.022 * (1.0 - p) * smoothstep(0.0, 0.2, p);
    vec2 dir = normalize(pos - org + vec2(0.0001, 0.0));
    vec2 off = vec2(dir.x / aspect, dir.y) * wave * amp;

    vec2 uv0 = clamp(uv + off, vec2(0.0), vec2(1.0));
    vec2 uv1 = clamp(uv + off * 1.6, vec2(0.0), vec2(1.0));
    vec2 uv2 = clamp(uv + off * 0.4, vec2(0.0), vec2(1.0));

    vec4 a = vec4(texture(fromTex, uv1).r, texture(fromTex, uv0).g, texture(fromTex, uv2).b, 1.0);
    vec4 b = vec4(texture(toTex, uv1).r, texture(toTex, uv0).g, texture(toTex, uv2).b, 1.0);

    vec4 col = mix(a, b, t);

    float wf = p * 1.3;
    float ring = exp(-abs(d - wf) * 26.0) * (1.0 - p) * 1.5;
    col.rgb += accent.rgb * ring;

    fragColor = col * qt_Opacity;
}