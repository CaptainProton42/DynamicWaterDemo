extends Spatial

onready var plop = preload("res://scenes/Plop.tscn")
onready var crate = preload("res://scenes/Crate.tscn")

onready var water = get_node("Water") 
onready var camera = get_node("CameraPivot/Camera")

var mouse_ray_length = 10000 # Ray length for mouse input detection
var mouse_click_delay = 0.2 # Mouse up and down within this time will count as click

var click_timer = 0.0

func _process(delta):
	click_timer += delta

# Spawn a new crate at position in local coordinates
func spawn_crate(position):
	var crate_inst = crate.instance()
	crate_inst.translation = position
	crate_inst.water_node_path = "../" + get_path_to(water)
	add_child(crate_inst)

# Show a "plop" effect at the mouse position.
func plop():
	var plop_inst = plop.instance()
	plop_inst.position = get_viewport().get_mouse_position()
	add_child(plop_inst)

func _on_reload_pressed():
	get_tree().reload_current_scene()

func _input(event):
	if Input.is_action_just_pressed("interact"):
		click_timer = 0.0 # Reset the click timer
	if Input.is_action_just_released("interact"):
		if click_timer < mouse_click_delay: # If within click delay threshold
			click_timer += mouse_click_delay
			# Start a ray cast from the mouse position on layer 2 (interactive objects)
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * mouse_ray_length
			var space_state = get_world().direct_space_state
			var result = space_state.intersect_ray(from, to, [], 2, true, false)

			if result: # Hit an object that is interactable
				result.collider._interact()
				plop()
			else: # Did not hit any interactable objects
				# Start a new raycast on layer 4 (crate spawn areas)
				result = space_state.intersect_ray(from, to, [], 4, false, true)
				if result: # Hit a spawn area
					spawn_crate(result.position)
					plop()