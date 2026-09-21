#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    vec4 pill;
    vec4 card;
    vec4 fillColour;
    vec4 lineColour;
    float pillR;
    float cardR;
    float k;
};

float sdRoundedBox(vec2 p, vec2 c, vec2 h, float r) {
    r = min(r, min(h.x, h.y));
    vec2 d = abs(p - c) - h + vec2(r);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

float smin(float a, float b, float s) {
    return max(s, min(a, b)) - length(max(vec2(s) - vec2(a, b), vec2(0.0)));
}

void main() {
    vec2 p = qt_TexCoord0 * res;

    float d = smin(sdRoundedBox(p, pill.xy, pill.zw, pillR),
                   sdRoundedBox(p, card.xy, card.zw, cardR),
                   k);

    float fw = max(fwidth(d), 0.0001);

    float fill = 1.0 - smoothstep(-fw, fw, d);
    float line = fill * smoothstep(-1.0 - fw, -1.0 + fw, d);

    float aFill = fillColour.a * fill;
    float aLine = lineColour.a * line;
    float outA = aLine + aFill * (1.0 - aLine);

    vec3 rgb = lineColour.rgb * aLine + fillColour.rgb * aFill * (1.0 - aLine);

    fragColor = vec4(rgb, outA) * qt_Opacity;
}
