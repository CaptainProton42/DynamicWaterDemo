extends "res://scripts/BuoyantBody.gd"

func _interact():
    # Push boat forwards on interaction
    self.add_central_force(to_global(Vector3(20000.0, 0.0, 0.0)) - global_transform.origin)
    angular_velocity = Vector3(0.0, 0.0, 0.0)