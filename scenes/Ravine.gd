extends Node3D

# General Ravine Properties
@export_range(10.0, 100.0, 5.0, "step") var ravine_length := 50.0
@export_range(10, 100, 1, "step") var subdivisions_x := 20
@export_range(10, 100, 1, "step") var subdivisions_z := 25
@export_range(1.0, 50.0, 1.0, "step") var ravine_depth := 30.0
@export_range(0.01, 0.5, 0.01, "step") var ravine_frequency := 0.1
@export_range(0.0, 50.0, 1.0, "step") var side_height := 10.0
@export_range(10.0, 100.0, 1.0, "step") var divot_width := 30.0 # The width of the divot at the top
@export_range(0.0, 50.0, 1.0, "step") var ravine_padding := 30.0 # Wiggle room on either side of the ravine
@export_range(0.0, 1.0, 0.05, "step") var base_flatness := 0.5
@export_range(0.0, 5.0, 0.1, "step") var rock_noise_strength := 4.0 # strength of the rock protrusions
@export_range(0.01, 1.0, 0.01, "step") var rock_noise_frequency := 1 # frequency of the rock protrusions

# --- Rock scattering properties ---
@export_range(10, 500, 1, "step") var rock_count := 25
# Increased the max rock scale to make rocks more visible
@export_range(1.0, 100.0, 0.5, "step") var max_rock_scale := 10.0
# Removed the `rock_flatness_threshold` as the new logic will handle this
# with a more continuous distribution.

# --- Preload the material directly from the file system ---
var rock_material = preload("res://Shaders/RockMaterial.material")
# --- Load the rock scenes from the Models folder ---
@export var rock_scenes: Array[PackedScene] = [
	preload("res://Models/Rocks1.glb"),
	preload("res://Models/Rocks2.glb"),
	preload("res://Models/Rocks3.glb")
]

# The total width of the chunk will now be dynamically calculated.
var ravine_width: float = 0.0

var ravine_noise: FastNoiseLite = null
var ravine_id: int = 0
var shader: ShaderMaterial = preload("res://Shaders/Ravine.tres")

# Use _ready() to make sure the rocks are scattered when the game starts
func _ready():
	#call_deferred("scatter_rocks")
	pass
func set_noise_reference(shared_ravine_noise: FastNoiseLite) -> void:
	ravine_noise = shared_ravine_noise

func generate_mesh(world_z_offset: float) -> void:
	if ravine_noise == null:
		push_error("Ravine.generate_mesh: ravine_noise is null.")
		return
	
	# Dynamically calculate the total width of the generated terrain.
	ravine_width = divot_width + (2.0 * ravine_padding)
	
	
	# Step 1: Make subdivided plane with the new, optimized size
	var plane := PlaneMesh.new()
	plane.size = Vector2(ravine_width, ravine_length)
	plane.subdivide_width = subdivisions_x
	plane.subdivide_depth = subdivisions_z

	# Step 2: Get arrays
	var arrays := plane.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	# Step 3: Prepare arrays for flat-shaded mesh
	var flat_verts := PackedVector3Array()
	var flat_normals := PackedVector3Array()

	for i in range(0, indices.size(), 3):
		# Get the triangle vertices
		var v0 = verts[indices[i]]
		var v1 = verts[indices[i + 1]]
		var v2 = verts[indices[i + 2]]

		# Get the ravine noise value.
		var noise_val0 = ravine_noise.get_noise_2d(0, (world_z_offset + v0.z) * ravine_frequency)
		var noise_val1 = ravine_noise.get_noise_2d(0, (world_z_offset + v1.z) * ravine_frequency)
		var noise_val2 = ravine_noise.get_noise_2d(0, (world_z_offset + v2.z) * ravine_frequency)
		
		# Calculate the x-position of the ravine's centerline.
		# It's clamped to ensure the ravine doesn't go outside the padded area.
		var ravine_center_x0 = clamp(noise_val0 * (ravine_width / 2.0), -divot_width / 2.0, divot_width / 2.0)
		var ravine_center_x1 = clamp(noise_val1 * (ravine_width / 2.0), -divot_width / 2.0, divot_width / 2.0)
		var ravine_center_x2 = clamp(noise_val2 * (ravine_width / 2.0), -divot_width / 2.0, divot_width / 2.0)
		
		# The distance is now calculated from the new vertex position, which is relative to the small plane
		var distance0 = abs(v0.x - ravine_center_x0)
		var distance1 = abs(v1.x - ravine_center_x1)
		var distance2 = abs(v2.x - ravine_center_x2)
		
		# Normalize the distance for the divot to a value between 0 and 1.
		var normalized_divot_distance0 = distance0 / (divot_width / 2.0)
		var normalized_divot_distance1 = distance1 / (divot_width / 2.0)
		var normalized_divot_distance2 = distance2 / (divot_width / 2.0)

		# Apply the depth, creating a U-shape.
		var ravine_curve0 = 1.0 - smoothstep(base_flatness, 1.0, normalized_divot_distance0)
		var ravine_curve1 = 1.0 - smoothstep(base_flatness, 1.0, normalized_divot_distance1)
		var ravine_curve2 = 1.0 - smoothstep(base_flatness, 1.0, normalized_divot_distance2)
		
		var v_shape_y0 = -ravine_depth * ravine_curve0
		var v_shape_y1 = -ravine_depth * ravine_curve1
		var v_shape_y2 = -ravine_depth * ravine_curve2
		
		# Normalize distance for the side height using the overall ravine width.
		var normalized_side_distance0 = distance0 / (ravine_width / 2.0)
		var normalized_side_distance1 = distance1 / (ravine_width / 2.0)
		var normalized_side_distance2 = distance2 / (ravine_width / 2.0)
		
		# Add a positive height to the sides.
		var side_y0 = pow(normalized_side_distance0, 2.0) * side_height
		var side_y1 = pow(normalized_side_distance1, 2.0) * side_height
		var side_y2 = pow(normalized_side_distance2, 2.0) * side_height
		
		# Add a new layer of noise for "rock protrusions"
		# This noise is based on the world position, but is applied to the local vertex.
		# We only want this effect on the steep walls, not the flat top.
		var rock_noise0 = ravine_noise.get_noise_3d(v0.x * rock_noise_frequency, v0.y * rock_noise_frequency, (world_z_offset + v0.z) * rock_noise_frequency)
		var rock_noise1 = ravine_noise.get_noise_3d(v1.x * rock_noise_frequency, v1.y * rock_noise_frequency, (world_z_offset + v1.z) * rock_noise_frequency)
		var rock_noise2 = ravine_noise.get_noise_3d(v2.x * rock_noise_frequency, v2.y * rock_noise_frequency, (world_z_offset + v2.z) * rock_noise_frequency)
		
		# We use smoothstep to make sure the effect only appears on the steep parts.
		var rock_effect_blend0 = 1.0 - smoothstep(0.95, 1.0, normalized_divot_distance0)
		var rock_effect_blend1 = 1.0 - smoothstep(0.95, 1.0, normalized_divot_distance1)
		var rock_effect_blend2 = 1.0 - smoothstep(0.95, 1.0, normalized_divot_distance2)
		
		v0.x += rock_noise0 * rock_noise_strength * rock_effect_blend0
		v0.y += rock_noise0 * rock_noise_strength * rock_effect_blend0
		v1.x += rock_noise1 * rock_noise_strength * rock_effect_blend1
		v1.y += rock_noise1 * rock_noise_strength * rock_effect_blend1
		v2.x += rock_noise2 * rock_noise_strength * rock_effect_blend2
		v2.y += rock_noise2 * rock_noise_strength * rock_effect_blend2
		
		# Combine the two shapes.
		v0.y = v_shape_y0 + side_y0
		v1.y = v_shape_y1 + side_y1
		v2.y = v_shape_y2 + side_y2
		
		# Calculate flat normal for this face
		var normal = Plane(v0, v1, v2).normal

		# Append vertices and normals
		flat_verts.append(v0)
		flat_verts.append(v1)
		flat_verts.append(v2)
		flat_normals.append(normal)
		flat_normals.append(normal)
		flat_normals.append(normal)

	# Step 4: Build mesh
	var new_arrays := []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = flat_verts
	new_arrays[Mesh.ARRAY_NORMAL] = flat_normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)

	# Step 5: Assign to MeshInstance
	$Terrain.mesh = mesh
	$CollisionShape3D.shape = mesh.create_trimesh_shape()
	$Terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	# Step 6: Apply the material for shading
	$Terrain.material_override = shader

# A helper function to find the first MeshInstance3D in a scene
# This is needed because the rock scenes are .glb files which may have other nodes
# like an inherited Node3D or a Camera, etc.
func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if not node:
		return null
	
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var found_mesh = _find_first_mesh_instance(child)
		if found_mesh:
			return found_mesh
	
	return null

func scatter_rocks():
	if rock_scenes.is_empty():
		push_warning("No rock scenes are assigned to the rock_scenes array. Skipping rock scattering.")
		return
	
	# Check if the RockScatter node exists. If not, create it.
	var multi_mesh_instance = find_child("RockScatter", true, false)
	if not multi_mesh_instance:
		multi_mesh_instance = MultiMeshInstance3D.new()
		multi_mesh_instance.name = "RockScatter"
		add_child(multi_mesh_instance)
	
	# Clear previous rocks
	multi_mesh_instance.multimesh = null
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Randomly select a scene from the array.
	var selected_scene = rock_scenes[rng.randi_range(0, rock_scenes.size() - 1)]
	
	# Instantiate the scene to get the mesh data.
	var instance = selected_scene.instantiate()
	var mesh_instance = _find_first_mesh_instance(instance)
	instance.queue_free()
	
	if not mesh_instance or not mesh_instance.mesh:
		push_error("Could not find a valid MeshInstance3D with a mesh in the selected rock scene.")
		instance.queue_free()
		return
		
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = mesh_instance.mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = rock_count
	
	multi_mesh_instance.multimesh = multi_mesh
	
	# --- Apply the rock material to the MultiMeshInstance3D node, not the MultiMesh resource ---
	if rock_material:
		multi_mesh_instance.material_override = rock_material
	
	# Get the mesh's AABB to normalize the scale.
	var mesh_aabb = mesh_instance.mesh.get_aabb()
	# We use the longest side of the bounding box to normalize the scale.
	var normalization_factor = 1.0 / max(mesh_aabb.size.x, mesh_aabb.size.y, mesh_aabb.size.z)
	
	# Clean up the temporary instance after we've gotten the mesh.
	instance.queue_free()
	
	var rocks_placed_count = 0
	while rocks_placed_count < rock_count:
		var rand_x = rng.randf_range(-ravine_width / 2.0, ravine_width / 2.0)
		var rand_z = rng.randf_range(-ravine_length, ravine_length)
		
		# Ravine centerline (same logic as mesh gen)
		var ravine_noise_val = ravine_noise.get_noise_2d(0, rand_z * ravine_frequency)
		var ravine_center_x = clamp(ravine_noise_val * (ravine_width / 2.0), -divot_width / 2.0, divot_width / 2.0)
		
		var distance = abs(rand_x - ravine_center_x)
		var normalized_divot_distance = distance / (divot_width / 2.0)
		
		# NEW LOGIC: Use a continuous probability distribution for scattering
		# A random number between 0 and 1. If it's less than (1 - normalized_divot_distance), place the rock.
		# This means rocks are most likely to appear at the center (normalized_divot_distance is 0)
		# and least likely on the edges (normalized_divot_distance is 1).
		if rng.randf() < (1.0 - normalized_divot_distance):
			
			# Rock scale - Now using the normalization factor to make scale consistent
			var random_scale = rng.randf_range(5.0, max_rock_scale)
			var scale_vec = Vector3.ONE * random_scale * normalization_factor
			
			# Embed rock at a fixed depth, as requested.
			var embedded_y = -ravine_depth
			
			# Rotation around Y
			var new_rotation = Basis(Vector3.UP, rng.randf_range(0, TAU))
			
			# Build transform (scale → rotation → position)
			var new_transform = Transform3D(new_rotation.scaled(scale_vec), Vector3(rand_x, embedded_y, rand_z))
			
			# Apply to multimesh
			multi_mesh.set_instance_transform(rocks_placed_count, new_transform)
			rocks_placed_count += 1

	
	
