# Camera script that rotates the camera around a parent pivot when "interact" action is pressed

extends Camera

export var speed = 0.005
export var limit_up_down = Vector2(-15.0, 15.0)

var drag_orig
var rot_orig

func _on_gui_input(event):
	if Input.is_action_just_pressed("interact"):
		# Set current origins
		drag_orig = get_viewport().get_mouse_position()
		rot_orig = get_parent().rotation
	if Input.is_action_pressed("interact"):
		get_parent().rotation.y = rot_orig.y-speed*(get_viewport().get_mouse_position() - drag_orig).x
		get_parent().rotation.x = clamp(rot_orig.x-speed*(get_viewport().get_mouse_position() - drag_orig).y, -25.0 / 180.0 * PI, 25.0 / 180.0 * PI)