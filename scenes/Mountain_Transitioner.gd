extends Node3D

@export var mountain_width := 100.0
@export var mountain_length := 10.0
@export var subdivisions_x := 40
@export var subdivisions_z := 5
@export var height_scale : float = 5.0
@export var min_height_scale: float = 5.0
@export var max_height_scale: float = 5.0
@export var noise_scale := 0.1

var noise: FastNoiseLite = null
var transition_id: int = 0
var shader: ShaderMaterial = preload("res://Shaders/TerrainShader.tres")
@onready var timer = $Transition_Timer
var height_inc = false

func set_noise_reference(shared_noise: FastNoiseLite) -> void:
	noise = shared_noise

func generate_mesh(world_z_offset: float) -> void:
	if noise == null:
		push_error("mountain.generate_mesh: noise is null — call set_noise_reference(shared_noise) first.")
		return
	if timer.time_left > 10:
		position.y = -height_scale/2
	# Step 1: Make subdivided plane
	var plane := PlaneMesh.new()
	plane.size = Vector2(mountain_width, mountain_length)
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

		# Apply noise to each vertex
		v0.y = noise.get_noise_2d(v0.x * noise_scale, (world_z_offset + v0.z) * noise_scale) * height_scale
		v1.y = noise.get_noise_2d(v1.x * noise_scale, (world_z_offset + v1.z) * noise_scale) * height_scale
		v2.y = noise.get_noise_2d(v2.x * noise_scale, (world_z_offset + v2.z) * noise_scale) * height_scale

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
	$Terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Step 6: Apply the material for shading
	$Terrain.material_override = shader
