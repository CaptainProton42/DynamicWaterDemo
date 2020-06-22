extends "res://scripts/BuoyantBody.gd"

func _interact():
    if sleeping:
        # Wake up surfboard on interaction
        sleeping = false
    else:
        # Push surfboard slightly in a random direction
        var dir = Vector3(100.0*randf() - 50.0, -50.0, 100.0*randf() -50.0)
        self.add_central_force(dir)