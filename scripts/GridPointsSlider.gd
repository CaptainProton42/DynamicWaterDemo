extends HSlider

signal grid_points_changed

func _on_value_changed(p_value):
	match int(p_value):
		7:
			get_node("Label").text = "Water Quality: 128 px"
		8:
			get_node("Label").text = "Water Quality: 256 px"
		9:
			get_node("Label").text = "Water Quality: 512 px"
	emit_signal("grid_points_changed", int(pow(2, p_value)))