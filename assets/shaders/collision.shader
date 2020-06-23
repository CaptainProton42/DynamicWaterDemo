shader_type spatial;

uniform float speed;

render_mode cull_front;

void fragment() {
	ALBEDO.r = speed;
}