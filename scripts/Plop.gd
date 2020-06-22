extends Node2D

export var color = Color(0.0, 0.0, 0.0, 1.0)

func _ready():
	get_node("Dash1/Line2D").default_color = color
	get_node("Dash2/Line2D").default_color = color
	get_node("Dash3/Line2D").default_color = color
	get_node("Dash4/Line2D").default_color = color
	get_node("Dash5/Line2D").default_color = color

	get_node("AnimationPlayer").play("anim")
	yield(get_node("AnimationPlayer"), "animation_finished")
	queue_free()
