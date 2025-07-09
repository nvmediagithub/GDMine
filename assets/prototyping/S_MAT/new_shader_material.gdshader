shader_type spatial;
varying flat vec3 flat_normal;

void vertex() {
    flat_normal = normalize( (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz );
}

void light() {
    float NdotL = max(dot(flat_normal, LIGHT), 0.0);
    DIFFUSE_LIGHT += NdotL * ATTENUATION * LIGHT_COLOR * vec3(0.8, 0.2, 0.0) + vec3(0.8, 0.2, 0.0) * 0.1;
}