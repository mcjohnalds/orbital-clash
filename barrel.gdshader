shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

vec2 distort(vec2 p)
{
    p = 2.0 * (p - vec2(0.5));
    float theta  = atan(p.y, p.x);
    float radius = length(p);
    radius = pow(radius, 1.04);
    p.x = radius * cos(theta);
    p.y = radius * sin(theta);
    return 0.5 * p + vec2(0.5);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    uv = clamp(uv, 0.0, 1.0);
    vec2 p = distort(uv);
    p = clamp(p, 0.0, 1.0);
    vec3 col = textureLod(screen_texture, p, 0.0).xyz;
    COLOR = vec4(col, 1.0);
}
