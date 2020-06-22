shader_type spatial;

uniform float speed;

render_mode world_vertex_coords, cull_front;

void vertex() {
	if (VERTEX.y < 0.0f) {
		VERTEX.y = 0.0f;
	}
	COLOR.r = speed;
}

void fragment() {
	ALBEDO.r = COLOR.r;
}