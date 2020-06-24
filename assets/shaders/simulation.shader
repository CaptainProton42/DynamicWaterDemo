shader_type canvas_item;

uniform float a;
uniform float amplitude;
uniform float grid_points;

uniform sampler2D z_tex;
uniform sampler2D old_z_tex;

uniform sampler2D collision_texture;
uniform sampler2D old_collision_texture;

uniform sampler2D land_texture;

void fragment() {
	float pix_size = 1.0f/grid_points;
	
	vec4 z = a * (texture(z_tex, UV + vec2(pix_size, 0.0f))
					   + texture(z_tex, UV - vec2(pix_size, 0.0f))
					   + texture(z_tex, UV + vec2(0.0f, pix_size)) 
					   + texture(z_tex, UV - vec2(0.0f, pix_size)))
				  + (2.0f - 4.0f * a) * (texture(z_tex, UV)) - (texture(old_z_tex, UV));
				
	float z_new_pos = z.r; // positive waves are stored in the red channel
	float z_new_neg = z.g; // negative waves are stored in the green channel
				
	float collision_state_old = texture(old_collision_texture, UV).r;
	float collision_state_new = texture(collision_texture, UV).r;
	
	if (collision_state_new > 0.0f && collision_state_old == 0.0f) {
		z_new_pos = amplitude * collision_state_new;
	} else if (collision_state_new == 0.0f && collision_state_old > 0.0f) {
		z_new_neg = amplitude * collision_state_old;
	}
	
	float land = texture(land_texture, UV).r;
	if (land > 0.0f) {
		z_new_pos = 0.0f;
		z_new_neg = 0.0f;
	}
	
	COLOR.r = z_new_pos;
	COLOR.g = z_new_neg;

	COLOR.b = 0.0f;
}