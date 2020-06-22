# This node returns a force on the y axis depending on how
# far submerged the node is.
# The force grows linearly with depth and thus does *not*
# follow Archimedes' law. However, I found that a linear
# dependence produces more realistic looking results for
# near the water surface.
# There is also a dampening factor to prevent instabilities.

extends Spatial

export var buoyancy = 5.0
export var drag = 0.18 # Drag factor (total dampening is buoyancy*dampening)

var water_node : Node

var force : float = 0.0

var velocity = Vector3(0.0, 0.0, 0.0)
var old_pos = Vector3(0.0, 0.0, 0.0)

func _physics_process(delta):
	if water_node:
		# Approximate the current velocity (needed for drag)
		var pos = global_transform.origin
		velocity = (pos - old_pos) / delta
		old_pos = pos

		# Get height of water at current position and calculate
		# the current displacement.
		var h = water_node.get_height(global_transform.origin)
		var disp = global_transform.origin.y - h
		if (disp < 0):
			force = buoyancy*(-disp - drag * velocity.y)
		else:
			# No force if above water
			force = 0.0