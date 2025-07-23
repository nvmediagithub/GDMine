shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Текстуры
uniform sampler2D albedo_map  : source_color;
uniform sampler2D normal_map  : hint_normal;
uniform sampler2D s_map       : hint_default_white;

// сила параллакса (красный канал s_map)
uniform float height_scale    : hint_range(0.0, 0.5, 0.001) = 0.02;

void fragment() {
    // 1) Геометрическая нормаль и тангент‑спейс базис
    vec3 n_geom = normalize(NORMAL);
    vec3 t      = normalize(TANGENT);   // vec3 в Godot 4
    vec3 b      = normalize(BINORMAL);  // встроенный битангенрут

    // 2) View‑вектор (view‑space)
    vec3 view_dir = normalize(VIEW);

    // 3) Перевод во «внутреннюю» систему тангентов (для параллакса)
    vec3 view_ts = vec3(
        dot(view_dir, t),
        dot(view_dir, b),
        dot(view_dir, n_geom)
    );

    // 4) Считаем смещение UV по высоте из R‑канала
    float height = texture(s_map, UV).r;
    vec2 uv_parallax = UV + height * height_scale * (view_ts.xy / view_ts.z);
    uv_parallax = clamp(uv_parallax, 0.0, 1.0);

    // 5) Сэмплинг по новым UV
    vec3 albedo      = texture(albedo_map, uv_parallax).rgb;
    vec3 nm_ts       = texture(normal_map, uv_parallax).rgb * 2.0 - 1.0;
    float smoothness = texture(s_map, uv_parallax).g;
    float metalness  = texture(s_map, uv_parallax).b;

    // 6) Построение нормали в view‑space через TBN
    vec3 normal_vs = normalize(
        t * nm_ts.x +
        b * nm_ts.y +
        n_geom * nm_ts.z
    );

    // 7) Выдача PBR‑параметров
    ALBEDO    = albedo;
    NORMAL    = normal_vs;
    METALLIC  = metalness;
    ROUGHNESS = 1.0 - smoothness;
}
