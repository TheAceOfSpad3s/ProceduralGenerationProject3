extends Node3D

# This is the rock mesh we will be instantiating
@export var rock_mesh: Mesh
# The total number of rocks to scatter
@export_range(100, 10000, 100, "step") var rock_count := 2000
# The scale range for the rocks to give them variety
@export_range(0.1, 5.0, 0.1, "step") var max_scale := 1.0
# The frequency and strength of the noise used to place the rocks on the ravine floor
@export_range(0.01, 1.0, 0.01, "step") var rock_noise_frequency := 0.2
@export_range(0.0, 5.0, 0.1, "step") var rock_noise_strength := 1.0

var multi_mesh_instance: MultiMeshInstance3D
var multi_mesh: MultiMesh

func _ready():
	multi_mesh_instance = $MultiMeshInstance3D
	
	# We can get the parent node automatically. This assumes the RockScatter
	# node is a child of the Ravine node.
	var ravine_chunk = get_parent()
	if not ravine_chunk:
		push_error("MultiMeshRockScatter: Could not find the parent Ravine node.")
		return
	
	# The Ravine script has the FastNoiseLite node
	var ravine_noise = ravine_chunk.ravine_noise

	# Now we only need to check if the rock_mesh is set
	if not rock_mesh or not ravine_noise:
		push_error("MultiMeshRockScatter: 'rock_mesh' or 'ravine_noise' is not set.")
		return
	
	scatter_rocks(ravine_noise, ravine_chunk)
	
func scatter_rocks(ravine_noise, ravine_chunk):
	# Step 1: Set up the MultiMesh
	multi_mesh = MultiMesh.new()
	multi_mesh.mesh = rock_mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = rock_count
	multi_mesh_instance.multimesh = multi_mesh
	
	# Get the ravine's width and depth from the main script
	# This is how we ensure the rocks are scattered correctly within the ravine
	var ravine_width = ravine_chunk.divot_width + (2.0 * ravine_chunk.ravine_padding)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Step 2: Loop to scatter the rocks
	for i in range(rock_count):
		# Get a random position within the ravine's bounds
		var rand_x = rng.randf_range(-ravine_width / 2.0, ravine_width / 2.0)
		var rand_z = rng.randf_range(-ravine_chunk.ravine_length / 2.0, ravine_chunk.ravine_length / 2.0)
		
		# Get the noise value for the ravine floor height at this position
		var ravine_noise_val = ravine_noise.get_noise_2d(rand_x * ravine_chunk.ravine_frequency, rand_z * ravine_chunk.ravine_frequency)
		var ravine_center_x = clamp(ravine_noise_val * (ravine_width / 2.0), -ravine_chunk.divot_width / 2.0, ravine_chunk.divot_width / 2.0)
		
		var distance = abs(rand_x - ravine_center_x)
		var normalized_divot_distance = distance / (ravine_chunk.divot_width / 2.0)
		
		var ravine_curve = 1.0 - smoothstep(ravine_chunk.base_flatness, 1.0, normalized_divot_distance)
		var ravine_y = -ravine_chunk.ravine_depth * ravine_curve
		
		# Add some random rock noise to the Y position for extra variety
		var rock_y_offset = ravine_noise.get_noise_3d(rand_x * rock_noise_frequency, ravine_y * rock_noise_frequency, rand_z * rock_noise_frequency) * rock_noise_strength
		
		# Step 3: Create the transform
		var new_transform = Transform3D()
		new_transform.origin = Vector3(rand_x, ravine_y + rock_y_offset, rand_z)
		
		# Randomize the rotation and scale
		var random_scale = rng.randf_range(0.5, max_scale)
		new_transform = new_transform.scaled(Vector3(random_scale, random_scale, random_scale))
		new_transform = new_transform.rotated(Vector3(0, 1, 0), rng.randf_range(0, PI * 2))
		
		# Step 4: Set the transform in the MultiMesh
		multi_mesh.set_instance_transform(i, new_transform)

