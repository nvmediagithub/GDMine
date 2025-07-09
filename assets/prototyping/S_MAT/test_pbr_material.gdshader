shader_type spatial;

uniform sampler2D albedo_tex;
uniform sampler2D normal_tex;
uniform sampler2D roughness_tex;
uniform sampler2D metallic_tex;

uniform float roughness_scalar = 1.0;
uniform float metallic_scalar = 1.0;

void fragment() {
    vec4 albedo_color = texture(albedo_tex, UV);
    ALBEDO = albedo_color.rgb;

    METALLIC = texture(metallic_tex, UV).r * metallic_scalar;
    ROUGHNESS = texture(roughness_tex, UV).r * roughness_scalar * 2.0 - 1.0;

    // Нормали (если есть карта нормалей)
    vec3 normal_map = texture(normal_tex, UV).rgb;
    NORMAL_MAP = (normal_map);
}
