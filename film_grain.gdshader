shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 original_color = texture(screen_texture, SCREEN_UV);
    float noise = (fract(sin(dot(UV, vec2(12.9898, 78.233 + TIME))) * 43758.5453) - 0.5) * 2.0;
    original_color.rgb += noise * amount;
    COLOR = clamp(original_color, 0.0, 1.0);
}
