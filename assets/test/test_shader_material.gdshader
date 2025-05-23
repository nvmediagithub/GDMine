shader_type spatial;

uniform sampler2D albedo_atlas;
uniform sampler2D splatmap;
uniform vec2 uv_scale;

void fragment() {
	vec2 uv = UV * uv_scale;

	vec4 weights = texture(splatmap, uv);
	weights /= (weights.r + weights.g + weights.b + weights.a + 0.001); // normalize

	vec4 tex_r = texture(albedo_atlas, uv / 4.0 + vec2(0.0, 0.0)); // material 0
	vec4 tex_g = texture(albedo_atlas, uv / 4.0 + vec2(0.25, 0.0)); // material 1
	vec4 tex_b = texture(albedo_atlas, uv / 4.0 + vec2(0.5, 0.0));  // material 2
	vec4 tex_a = texture(albedo_atlas, uv / 4.0 + vec2(0.75, 0.0)); // material 3

	ALBEDO = tex_r.rgb * weights.r + tex_g.rgb * weights.g + tex_b.rgb * weights.b + tex_a.rgb * weights.a;
}
