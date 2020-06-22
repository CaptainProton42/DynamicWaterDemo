shader_type spatial;

render_mode specular_toon;

uniform vec4 water_color : hint_color;
uniform sampler2D simulation_texture;
uniform sampler2D collision_texture;
uniform float amplitude;

void vertex() {
	if (COLOR.r > 0.0f && texture(collision_texture, UV).r == 0.0f) {
		float v = COLOR.r;
		vec4 tex = texture(simulation_texture, UV);
		float height = tex.r - tex.g;
		VERTEX.y += amplitude * v * height;
	}
}

void fragment() {
	if (COLOR.r > 0.0f) {
		float v = COLOR.r;
		vec4 tex = texture(simulation_texture, UV);
		vec4 tex_dx = texture(simulation_texture, UV + vec2(0.01, 0.0));
		vec4 tex_dy = texture(simulation_texture, UV + vec2(0.0, 0.01));
		float height = tex.r - tex.g;
		float height_dx = tex_dx.r - tex_dx.g;
		float height_dy = tex_dy.r - tex_dy.g;
		NORMAL = v * normalize(mat3(INV_CAMERA_MATRIX)*(vec3(height_dx - height, 1.0, height_dx - height) / 0.01)) + (1.0f - v) * NORMAL;
	}
	
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	ALBEDO = water_color.rgb + (0.1f * fresnel);
	ALPHA = 0.8f;
}