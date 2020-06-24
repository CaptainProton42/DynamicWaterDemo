extends MeshInstance

onready var simulation_viewport = get_node("SimulationViewport") # Viewport that contains the simulation texture
onready var collision_viewport = get_node("CollisionViewport") # Viewport that contains the collision texture
onready var simulation_material = simulation_viewport.get_node("ColorRect").material # Material that contains the simulation shader
onready var surface_material = get_surface_material(0)

export(int, 1, 99999) var grid_points = 512 setget set_grid_points, get_grid_points # number of grid points in discretisation
export var c = 0.065 # wave speed
export var simulation_amplitude = 0.5  # amplitude of newly created waves in the simulation
export var mesh_amplitude = 1.0 # amplitude of waves in the mesh shader
export var land_texture : Texture

# Size of the water body in both dimensions
var water_size = 50.0

# Current height map of the surface as raw byte array
var surface_data = PoolByteArray()

# Viewport textures that contain the rendered height and collision maps
var simulation_texture
var collision_texture

func update_collision_texture():
	# Update the collision maps
	var img = collision_texture.get_data() # Get the currently rendered map
	# Set current map as old map
	var old_collision_texture = simulation_material.get_shader_param("collision_texture")
	simulation_material.get_shader_param("old_collision_texture").set_data(old_collision_texture.get_data())
	simulation_material.get_shader_param("collision_texture").set_data(img) # Set the current collision map from current render

func update_height_map():
	# Update the height maps
	var img = simulation_texture.get_data() # Get currently rendered map
	# Set current map as old map
	var old_height_map = simulation_material.get_shader_param("z_tex")
	simulation_material.get_shader_param("old_z_tex").set_data(old_height_map.get_data())
	simulation_material.get_shader_param("z_tex").set_data(img) # Set the current height map from current render

func _physics_process(delta):
	_update(delta)
	surface_data = simulation_texture.get_data().get_data()

var lock = false
func _update(delta):
	if not lock:
		lock = true
		update_collision_texture()
		update_height_map()
		
		# Render one frame of the simulation viewport to update the simulation
		simulation_viewport.render_target_update_mode = Viewport.UPDATE_ONCE

		# Wait until the frame is rendered, then unlock
		yield(get_tree(), "idle_frame")
		lock = false

func set_grid_points(p_grid_points):
	grid_points = p_grid_points
	if is_inside_tree():
		# Set viewport sizes to simulation grid size
		simulation_viewport.size = Vector2(grid_points, grid_points)
		collision_viewport.size = Vector2(grid_points, grid_points )
		simulation_viewport.get_node("ColorRect").rect_size = Vector2(grid_points, grid_points)
		simulation_material.set_shader_param("grid_points", grid_points)
		_initialize()

func get_grid_points():
	return grid_points

func _ready():
	simulation_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED

	# Set simulation and collision textures from viewports
	simulation_texture = simulation_viewport.get_texture()
	collision_texture = collision_viewport.get_texture()
	simulation_texture.flags = Texture.FLAG_FILTER # improves quality for low grid resolutions

	set_grid_points(grid_points)

	# Set uniforms of mesh shader
	surface_material.set_shader_param("simulation_texture", simulation_texture)
	surface_material.set_shader_param("collision_texture", collision_texture)
	surface_material.set_shader_param("amplitude", mesh_amplitude)

func _initialize():
	# Create an empty texture
	var img = Image.new()
	img.create(grid_points, grid_points, false, Image.FORMAT_RGB8)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	tex.flags = 0

	# Initialize the simulation with the empty texture
	simulation_material.set_shader_param("z_tex", tex)
	simulation_material.set_shader_param("old_z_tex", tex.duplicate())
	simulation_material.set_shader_param("collision_texture", tex.duplicate())
	simulation_material.set_shader_param("old_collision_texture", tex.duplicate())
	simulation_material.set_shader_param("land_texture", land_texture)

	# Set simulation parameters
	var delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_fps")
	var a = c*delta*grid_points
	a *= a
	if a > 0.5:
		push_warning("a > 0.5; Unstable simulation.")
	simulation_material.set_shader_param("a", a)
	simulation_material.set_shader_param("amplitude", simulation_amplitude)

func get_height(global_pos):
	# Get the height at the 
	var local_pos = to_local(global_pos)

	# Get pixel position
	var y = int((local_pos.x + water_size / 2.0) / water_size * (grid_points))
	var x =	int((local_pos.z + water_size / 2.0) / water_size * (grid_points))

	# Just return a very low height when not inside texture
	if x > grid_points - 1 or y > grid_points - 1 or x < 0 or y < 0:
		return -99999.9

	# Get height from surface data (in RGB8 format)
	# This is faster than locking the image and using get_pixel()
	var height = mesh_amplitude * (surface_data[3*(x*(grid_points) + y)] - surface_data[3*(x*(grid_points) + y) + 1]) / 255.0
	return height
