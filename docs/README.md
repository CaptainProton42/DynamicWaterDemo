# Dynamic Water

<div align="center"><iframe width="730px" height="730px" frameBorder="0" src="water.html"></iframe></div>

Click anywhere to interact with objects or spawn crates. You can also change the quality of the water texture and reset the scene.

## Implementation

My implementation uses a finite-differencing method in order to solve the physical equation governing the behaviour of open water surface waves, the wave equation, on a grid. I used the paper [Real-Time Open Water Environments with Interacting Objects](https://www.researchgate.net/publication/221314832_Real-Time_Open_Water_Environments_with_Interacting_Objects) by H. Cords and O. Staadt as a reference. If you want to know more about the technical aspects of this implementation or more advanced techniques like infinite water, it's a really good read.

## The wave equation

An important equation in phyiscs is the so-called [wave equation](https://en.wikipedia.org/wiki/Wave_equation). It describes the propagation of many types of waves like water waves, sound waves and even light. It therefore plays an important role in many fields of physics like optics and fluid dynamics, acoustics and electrodynamics.

The equation itself is a [hyperbolic partial differential equation of second order](https://en.wikipedia.org/wiki/Hyperbolic_partial_differential_equation). If this sounds very complex, don't worry, the equation itself is actually quite short:

$$\Delta f(\mathbf{x}, t) - \frac{1}{c^2} \frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} = 0$$

Here, $$t$$ is the current time, $$\mathbf{x} \in \mathbb{R}^2$$ is the position on the water surface and $$c$$ is the wave speed. $$f(\mathbf{x}, t)$$ then denotes the displacement, that is the height, of the water surface at the observed position $$\mathbf{x}$$ and time $$t$$.

The opertator $$\Delta$$ is the so-called Laplace operator and denotes the sum of the second spatial derivatives in every direction:

$$\Delta = \frac{\partial^2}{\partial x^2} + \frac{\partial^2}{\partial y^2}$$

Thus we can see that the wave equation connects the second spacial derivates of the water surface with its second derivative in time. This property results in the motion of waves as we would observe it in nature.

## The finite difference method

So now that we know what equation we want to solve we still have to figure out how to solve it. Generally, this cannot be done analytically so we resort to a very popular numerical method: [the finite difference method](https://en.wikipedia.org/wiki/Finite_difference_method). In this method, we discretise the area in which we want to solve our equation into a grid. We then want to retreive the approximate solution at each point of that grid.

So since we are discretizing the water surface we need to discretize the wave equation as well. For this, we use *stencils*. More specifically, a *five point stencil* for the second derivative in space and a *three point stencil* for the second derivative in time.

Let's start with the spatial derivative: As stated previously, we dicretize the water surface as a grid. Let's denote $$z_{i, j}$$ as the value of the function $$f$$ at the grid coordinates $$(i, j)$$. Using a *five point stencil* we can then *approximate* the derivative at that point as

$$\begin{aligned}
\Delta f(\mathbf{x}_{ij}) &= \frac{\partial^2 f(\mathbf{x}_{i, j})}{\partial x^2} + \frac{\partial^2 f(\mathbf{x}_{i, j})}{\partial y^2} \\
&\approx \frac{z_{i+1, j} - 2 \cdot z_{i, j} + z_{i-1, j}}{h^2} + \frac{z_{i, j+1} - 2 \cdot z_{i, j} + z_{i, j-1}}{h^2} \\
&= \frac{z_{i+1, j} + z_{i, j+1} - 4 \cdot z_{i, j} + z_{i-1, j} + z_{i, j-1}}{h^2}
\end{aligned}$$

where $$h$$ is the distance between to grid points which is assumed to be equal in $$x$$ and $$y$$ direction. So, in order get the second spatial derivative at point $$(i, j)$$ we need to sample all direct (non-diagonal) neighbours of that point (see the figure below).

<div align="center"><img width="30%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/stencil.png"></div>

However, the wave equation also contains a second time derivative which we need to discretize as well. For the time discretization, we simply use the physics process delta time $$\Delta t$$ (which is a constant in Godot). We use the upper index $$t$$ to denote the point in time. The complete notation is $$z_{i, j}^t$$ for the displacement at grid coordinates $$(i, j)$$ and time $$t$$. In order to now approximate the second time derivate, we can just use the following three-point-stencil:

$$\frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} \approx \frac{z_{i, j}^{t+1} - 2 \cdot z_{i, j}^t + z_{i, j}^{t-1}}{\Delta t^2}$$

Now that we have dicretized both derivatives, let's just plug them back into the initial wave equation and solve for $$z_{i, j}^{t+1}$$:

$$\begin{align}
0 &= \Delta f(\mathbf{x}, t) - \frac{1}{c^2} \frac{\partial^2 f(\mathbf{x}, t)}{\partial t^2} \\
0 &= \frac{z_{i+1, j} + z_{i, j+1} - 4 \cdot z_{i, j} + z_{i-1, j} + z_{i, j-1}}{h^2} - \frac{1}{c^2} \cdot \frac{z_{i, j}^{t+1} - 2 \cdot z_{i, j}^t + z_{i, j}^{t-1}}{\Delta t^2}\\
z_{i, j}^{t+1} &= a \cdot (z_{i+1, j}^t + z_{i, j+1}^t + z_{i-1, j}^t + z_{i, j-1}^t) + (2 - 4a) \cdot z_{i, j}^t - z_{i, j}^{t-1}
\end{align}$$

where we introduce $$a = \frac{c^2 \Delta t^2}{h^2}$$. In order to obtain a stable simulation, $$a < 0.5$$ needs to hold true. We thus have some limits on our choice of $\Delta t$ and $h$, depending on how fast our waves should propagate. Grids with less points (and thus large $$h$$) are generally more stable but also less accurate. It is desirable to keep $$\Delta t$$ as small as reasonably possible which means high framerates will benefit our simulation.

**Let's break down the final equation:** In order to update and retreive $$z_{i, j}^{t+1}$$, we need to know the grid neighbouring grid values at time $$t$$ as well as the previous displacement values at time $$t$$ and $$t-1$$. We can start our grid from any arbitrary initial conditions and let it evolve over time.

Now that we know the theory, let's get to the actual implementation.

## Implementation

In order to bring the finite difference method to life, I used fragment shaders. Textures are basically just two-dimensional grids that can hold values (colors) at each grid point (pixel). We make use of this convenient property and simply use a texture as the grid for our finite difference method.

In the editor, I created a new viewport called `SimulationViewport`. This viewport in return contains a `ColorRect` as shown below.

<div align="center"><img width="30%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/implementation.PNG"></div>

I then applied a shader to the `ColorRect` which contains the simulation code. The pixel size of the `ColorRect` thus defines the size of our simulation grid. Two textures are passed as uniforms to this shader: `z_tex` which holds the grid values $$z_{i, j}^t$$ and `z_old_tex` which holds the grid values $$z_{i, j}^{t-1}$$. The resulting values $$z_{i, j}^{t+1}$$ are then rendered to the `ColorRect` by the fragment shader. In order to retreive the current grid values, we can then simply retreive the contents of `SimulationViewport` with a `ViewportTexture`.

The snippet below contains the part of the simulation shader assigned to `ColorRect` which does the heavy lifting:

```
void fragment() {
	float pix_size = 1.0f/grid_points;

	vec4 z = a * (texture(z_tex, UV + vec2(pix_size, 0.0f))
		   + texture(z_tex, UV - vec2(pix_size, 0.0f))
		   + texture(z_tex, UV + vec2(0.0f, pix_size)) 
		   + texture(z_tex, UV - vec2(0.0f, pix_size)))
		+ (2.0f - 4.0f * a) * (texture(z_tex, UV))
		- (texture(old_z_tex, UV));

	float z_new_pos = z.r; // positive waves are stored in the red channel
	float z_new_neg = z.g; // negative waves are stored in the green channel

	...

	COLOR.r = z_new_pos;
	COLOR.g = z_new_neg;
}
```

*Note that I store "positive" waves in the red and "negative" waves in the green channel. This is not particularly important now and I will explain this later on.*

You can see that we first the neighbouring grid values as well as the current and last values at the grid position and then combine them according to our formula. The resulting value is then assigned to `COLOR`.

We also need a script that updates the simulation as well as grid textures each step. This is done in a script assigned to the `Water` Node. `_update` is called each physics frame:

```
func _update():
           ...
           update_height_map()

           # Render one frame of the simulation viewport to update the simulation
           simulation_viewport.render_target_update_mode = Viewport.UPDATE_ONCE

           # Wait until the frame is rendered
           yield(get_tree(), "idle_frame")
           ...

func update_height_map():
	# Update the height maps
	var img = simulation_texture.get_data() # Get currently rendered map
	# Set current map as old map
	var old_height_map = simulation_material.get_shader_param("z_tex")
	simulation_material.get_shader_param("old_z_tex").set_data(old_height_map.get_data())
	# Set the current height map from current render
	simulation_material.get_shader_param("z_tex").set_data(img)
```

And that's it for our basic simulation. We now know how to propagate waves along the surface but have yet to create them.

## Creating waves

When considering a boat moving through water, we need to be aware of two "types" of waves, *bow* waves and *stern* waves. Bow waves are created were the the boat's hull pushes away the water. Stern waves, on the other hand, are created behind the boat, where water is rushing back to fill the space the boat previously occupied. We thus create *positive* bow waves in front of the boat and *negative* stern waves behind the boat. Creating positive or negative waves just means manually setting grid points to positive or negative values.

The intensity of both creatd wave types will also depend on the speed of the boat: The faster the boat, the higher the waves.

In order to create waves we first need to know *where* to create them. We thus need to know the intersection of the boat's hull with the water surface.

I used a little trick to accomplish this. It's not perfect and makes some assumptions but it works reasonably well for simple objects:

I created a second viewport called `CollisionViewport`. This viewport will hold a texture which contains the intersections of all floating objects with the surface.

I then added a new camera called `CollisionCamera` to `CollisionViewport`. This camera uses on orthogonal projection and has its size set to the size of the water surface. The near plane is set to match the water surface and the far plane should be moved sufficiently far away.

<div align="center"><img width=75%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/viewing_frustum.png"></div>

Next, I added a mesh to every node that should be able to create waves and called in `CollisionMesh`. This mesh defines the hull of our boat.

<div align="center"><img width="30%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/collision_mesh.png"></div>

This mesh has a special material: It consists of two passes: The first one is a shader material with a shader like this:

```
shader_type spatial;

uniform float speed;

render_mode cull_front;

void fragment() {
	ALBEDO.r = speed;
}
```

The second pass is just a `SpatialMaterial` with albedo set to black and a higher render priority.

The resulting material will draw the *inside* of the mesh whatever color we set it to and the *outside* plain black. Since the camera culls every fragment above the water surface, it will draw the inside of objects that intersect the surface. The viewport texture will then be black where there is no intersection and colored where a hull intersects.

We can also give information about the speed of objects to the `CollisionViewport` by setting the `speed` uniform of the shader which will then be written to the red channel of the viewport texture.

<div align="center"><img width="40%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/wave_areas.png"></div>

Now that we have a texture containing the intersection of the boat hull with the surface we can pass this texture to our simulation shader and call it `collision_texture`. We also supply the collision texture from the *last frame* and call it `collision_texture_old`. We then read the red channels of both textures to `collision_state_new` and `collision_state_old`. By comparing these two values, we can differentiate between two important cases by adding the code below to our simulation fragment shader:

```
void fragment() {
	...
	float collision_state_old = texture(old_collision_texture, UV).r;
	float collision_state_new = texture(collision_texture, UV).r;
	
	if (collision_state_new > 0.0f && collision_state_old == 0.0f) {
		z_new_pos = amplitude * collision_state_new;
	} else if (collision_state_new == 0.0f && collision_state_old > 0.0f) {
		z_new_neg = amplitude * collision_state_old;
	}
	...
}
```

As noted previously, *positive* waves are created on the red channel and *negative* waves are created on the green channel. This is perfectly fine however, since waves do not interact and can computed in components which then later can be added up (you may now this phenomenon from [Waver interference](https://en.wikipedia.org/wiki/Wave_interference). The actual displacement or wave height simply can be retreived by subtracting the green channel from the red channel.

I also created a function `update_collision_texture` in the script of the `Water` node which works much like `update_height_map` in order to keep the collision textures up to date with `CollisionViewport`.

<div align="center"><img width="80%" src="https://github.com/CaptainProton42/DynamicWaterDemo/raw/media/wave_creation.gif"></div>

## Land masses

Other than boats or similar moving objects we can also have land masses like islands breaking the water surface. These objects obviously don't move but it would still be nice to have them interact with the water by breaking waves, especially since they are often larger.

This can be accomplished by passing a third type of texture to the simulation shader. I call it `land_texture`. Since the land masses do not move, this texture can be baked before starting the scene (or crudely drawn in Paint, in my case). The land texture used for the demo scene above, for example simply looks like this:

<div align="center"><img width="30%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/master/assets/textures/land_texture.png"></div>

It is simply white wherever land should be and black where there is open water.

We can then add a few lines to our simulation shader to prevent waves from passing through the white areas:

```
float land = texture(land_texture, UV).r;
if (land > 0.0f) {
	z_new_pos = 0.0f;
	z_new_neg = 0.0f;
}
```

Our *complete* simulation shader now looks like this:

```
shader_type canvas_item;

uniform sampler2D old_z_tex;
uniform sampler2D z_tex;

uniform float a;
uniform float amplitude;
uniform float grid_points;

uniform sampler2D collision_texture;
uniform sampler2D old_collision_texture;

uniform sampler2D land_texture;

void fragment() {
	float pix_size = 1.0f/grid_points;
	
	vec4 z = a * (texture(z_tex, UV + vec2(pix_size, 0.0f))
		      + texture(z_tex, UV - vec2(pix_size, 0.0f))
		      + texture(z_tex, UV + vec2(0.0f, pix_size)) 
		      + texture(z_tex, UV - vec2(0.0f, pix_size)))
		 + (2.0f - 4.0f * a) * (texture(z_tex, UV))
		 - (texture(old_z_tex, UV));
				
	float z_new_pos = z.r; // positive waves are stored in the red channel
	float z_new_neg = z.g; // negative waves are stored in the green channel
				
	float collision_state_old = texture(old_collision_texture, UV).r;
	float collision_state_new = texture(collision_texture, UV).r;
	
	if (collision_state_new > 0.0f && collision_state_old == 0.0f) {
		z_new_pos = amplitude * collision_state_new;
	} else if (collision_state_new == 0.0f && collision_state_old > 0.0f) {
		z_new_neg = amplitude * collision_state_old;
	}
	
	float land = texture(land_texture, UV).r;
	if (land > 0.0f) {
		z_new_pos = 0.0f;
		z_new_neg = 0.0f;
	}
	
	COLOR.r = z_new_pos;
	COLOR.g = z_new_neg;
}
```

## RigidBody interaction

So we can create waves now but in case we want to create an actual boat as a `RigidBody`, it will still simply fall through the water never to be seen again. In order to prevent this, we need to implement some form of interaction with the water surface.

For this, I created a new node, `BuoyancyProbe`. The script of this node is quite short:

```
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
```

It detects how far it is currently submerged by retreiving the current height of the water surface via the function `get_height` on the `Water` node which is defined as follows:

```
func _physics_process(delta):
	_update(delta)
	surface_data = simulation_texture.get_data().get_data()
	
func get_height(global_pos):
	# Get the height at the 
	var local_pos = to_local(global_pos)

	# Get pixel position
	var y = int((local_pos.x + 25.0) / 50.0 * (grid_points))
	var x =	int((local_pos.z + 25.0) / 50.0 * (grid_points))

	# Just return a very low height when not inside texture
	if x > grid_points - 1 or y > grid_points - 1 or x < 0 or y < 0:
		return -99999.9

	# Get height from surface data (in RGB8 format)
	# This is faster than locking the image and using get_pixel()
	var height = mesh_amplitude * (surface_data[3*(x*(grid_points) + y)] - surface_data[3*(x*(grid_points) + y) + 1]) / 255.0
	return height
```

*I read directly from the raw data of the `SimulationViewport` texture's image so that I don't have to lock the image in order to do a pixel read for every `BuoyancyProbe` in the scene which would get very slow.*

In case the `BuoyancyProbe` detects that it is underwater, it sets its `force` property to a value that depends linear on the submergence depth. Note, that this is not physically correct as the buoyant force actually depends on the mass that has been displaced by the object. Archimedes actually does look a bit sad now:

<div align="center"><img width="30%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/archimedes.png"></div>

However, a linear force will go to zero at the water surface and makes for a much smoother simulation.

We can now add `BuoyancyProbes` as children to `RigidBody`s that we want to be buoyant at strategist positions and accumulate the resulting forces from a script like this:

```
for i in range(probes.get_child_count()):
	if probes.get_child(i).force > 0.0:
		add_force(Vector3(0.0, probes.get_child(i).force, 0.0) / probes.get_child_count(),
		to_global(probes.get_child(i).translation) - global_transform.origin)
```

<div align="center"><img width="50%" src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/buoyancy_probes.PNG"></div>

And that's it! Our simulation is complete! We still need to visualize the water surface though since right now it is only written to the `SimulationViewport`'s texture.

## Graphics

Visualising the water surface is quite easy. We already have the height map in the red and green channels of the `SimulationViewport`'s texture. The idea is, to read these values and set the vertex positions and normals of the water surface inside a shader accordingly.

For this, I created a simple cuboid in blender. I rounded the edges a bit to make it more visually pleasing and then subdivided the top face of the cuboid into a grid. Note that this grid does not need to have the same resolution as the simulation grid. For me 200 x 200 vertices achieved reasonably pleasing results. I set the vertex colors of the grid vertices (that is the vertices that should actually be displaced) to red while leaving all the other vertices black and also UV mapped the surface so that the UVs on the grid go from 0 to 1 in both surface directions.

<div style="display: flex">
  <div style="flex: 33.33%; padding: 5px">
    <img src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/water_mesh_1.PNG" width="100%">
  </div>
  <div style="flex: 33.33%; padding: 5px">
    <img src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/water_mesh_2.PNG" width="100%">
  </div>
  <div style="flex: 33.33%; padding: 5px">
    <img src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/water_mesh_3.PNG" width="100%">
  </div>
</div>

I then simply added a shader to the mesh and displaced the vertices by reading from the height map:

```
void vertex() {
	if (COLOR.r > 0.0f && texture(collision_texture, UV).r == 0.0f) {
		float v = COLOR.r;
		vec4 tex = texture(simulation_texture, UV);
		float height = tex.r - tex.g;
		VERTEX.y += amplitude * v * height;
	}
}
```

The quality of the water is much improved by also calculating the normals in the fragment shader:

```
void fragment() {
	if (COLOR.r > 0.0f) {
		float v = COLOR.r;
		vec4 tex = texture(simulation_texture, UV);
		vec4 tex_dx = texture(simulation_texture, UV + vec2(0.01, 0.0));
		vec4 tex_dy = texture(simulation_texture, UV + vec2(0.0, 0.01));
		float height = tex.r - tex.g;
		float height_dx = tex_dx.r - tex_dx.g;
		float height_dy = tex_dy.r - tex_dy.g;
		NORMAL = v * normalize(mat3(INV_CAMERA_MATRIX)*(vec3(height_dx - height, 1.0, height_dx - height) / 0.01)) + (1.0f - v) * NORMAL;
	}
	
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	ALBEDO = water_color.rgb + (0.1f * fresnel);
	ALPHA = 0.8f;
}
```

Note, that in the first line of the vertex shader

```
if (COLOR.r > 0.0f && texture(collision_texture, UV).r == 0.0f) ...
```
we do not only check the vertex color but also the collision texture from `CollisionViewport`. This is to prevent waves from "glitching" through the boat: We do not visualise waves when the boat is currently intersecting with them. Below is a comparison without and with this tweak in place:

<div style="display: flex">
  <div align="center" style="flex: 50%; padding: 5px">
    <img src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/water_glitch_1.png" width="50%">
  </div>
  <div align="center" style="flex: 50%; padding: 5px">
    <img src="https://raw.githubusercontent.com/CaptainProton42/DynamicWaterDemo/media/water_glitch_2.png" width="50%">
  </div>
</div>
