shader_type spatial;

// Используем отбрасывание задних граней и режим unshaded для простоты (без влияния освещения)
render_mode cull_back, unshaded, depth_draw_opaque;

// uniform для текстуры, с подсказкой для редактора (hint_albedo) – это текстура, которую будем менять
uniform sampler2D albedo_texture : source_color;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
}
