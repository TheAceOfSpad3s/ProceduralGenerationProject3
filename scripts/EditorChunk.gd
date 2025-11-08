#EditorChunk.gd
@tool
extends Node3D

# Exported variables for tweaking in the Inspector
# Each variable's setter now directly triggers a mesh update.
@export var chunk_width := 80:
	set(value):
		chunk_width = value
		_update_mesh_and_material_in_editor()
@export var chunk_length := 50:
	set(value):
		chunk_length = value
		_update_mesh_and_material_in_editor()
@export var subdivisions_x := 20:
	set(value):
		subdivisions_x = value
		_update_mesh_and_material_in_editor()
@export var subdivisions_z := 25:
	set(value):
		subdivisions_z = value
		_update_mesh_and_material_in_editor()
@export_range(0.0, 50.0) var height_scale := 10.0:
	set(value):
		height_scale = value
		_update_mesh_and_material_in_editor()
@export_range(0.0, 1.0) var noise_scale := 0.1:
	set(value):
		noise_scale = value
		_update_mesh_and_material_in_editor()
@export var noise_seed := 1:
	set(value):
		noise_seed = value
		_update_mesh_and_material_in_editor()
@export var low_color: Color = Color(0.0, 0.6, 0.0, 1.0):
	set(value):
		low_color = value
		_update_mesh_and_material_in_editor()
@export var high_color: Color = Color(0.8, 0.8, 0.8, 1.0):
	set(value):
		high_color = value
		_update_mesh_and_material_in_editor()
@export_range(-20.0, 0.0) var min_height: float = -5.0:
	set(value):
		min_height = value
		_update_mesh_and_material_in_editor()
@export_range(0.0, 50.0) var max_height: float = 20.0:
	set(value):
		max_height = value
		_update_mesh_and_material_in_editor()
@export_range(0.0, 1.0) var slope_threshold := 0.6:
	set(value):
		slope_threshold = value
		_update_mesh_and_material_in_editor()

var noise: FastNoiseLite = null
var chunk_id: int = 0
var mat: ShaderMaterial = preload("res://Shaders/TerrainShader.tres")

# This function is the single point of truth for updating the mesh and material.
# It's now called from every setter function.
func _update_mesh_and_material_in_editor() -> void:
	var my_parent_node = get_node("Terrain")
	var children = my_parent_node.get_children()
	for child in children:
		child.queue_free()
	
	if Engine.is_editor_hint():
		if noise == null:
			noise = FastNoiseLite.new()
			noise.seed = noise_seed
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.1
			noise.fractal_octaves = 4
		
		# Generate the mesh with the new values
		_generate_mesh_from_properties(0.0)
		
		# Update shader uniforms to reflect the new colors/heights
		mat.set_shader_parameter("low_color", low_color)
		mat.set_shader_parameter("high_color", high_color)
		mat.set_shader_parameter("min_height", min_height)
		mat.set_shader_parameter("max_height", max_height)
		mat.set_shader_parameter("world_y_offset", global_position.y)
		mat.set_shader_parameter("slope_threshold", slope_threshold)
		
		$Terrain.material_override = mat

		# Notify the editor that the property list has changed
		notify_property_list_changed()

# Set the noise reference from the ChunkManager.gd script
func set_noise_reference(shared_noise: FastNoiseLite) -> void:
	noise = shared_noise

func _ready() -> void:
	# This runs both in the editor and at runtime.
	_update_mesh_and_material_in_editor()

func _generate_mesh_from_properties(world_z_offset: float) -> void:

	if noise == null:
		push_error("Chunk.generate_mesh: noise is null — call set_noise_reference(shared_noise) first.")
		return

	if not has_node("Terrain"):
		push_error("Chunk.gd: A child node named 'Terrain' was not found!")
		return
	
	var terrain_node = get_node("Terrain")
	if not terrain_node.is_class("MeshInstance3D"):
		push_error("Chunk.gd: The 'Terrain' node is not a MeshInstance3D!")
		return
	
	
	var plane := PlaneMesh.new()
	plane.size = Vector2(chunk_width, chunk_length)
	plane.subdivide_width = subdivisions_x
	plane.subdivide_depth = subdivisions_z

	var arrays := plane.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	var flat_verts := PackedVector3Array()
	var flat_normals := PackedVector3Array()

	for i in range(0, indices.size(), 3):
		var v0 = verts[indices[i]]
		var v1 = verts[indices[i + 1]]
		var v2 = verts[indices[i + 2]]

		# Apply noise to each vertex
		v0.y = noise.get_noise_2d(v0.x * noise_scale, (world_z_offset + v0.z) * noise_scale) * height_scale
		v1.y = noise.get_noise_2d(v1.x * noise_scale, (world_z_offset + v1.z) * noise_scale) * height_scale
		v2.y = noise.get_noise_2d(v2.x * noise_scale, (world_z_offset + v2.z) * noise_scale) * height_scale

		var normal = Plane(v0, v1, v2).normal

		flat_verts.append(v0)
		flat_verts.append(v1)
		flat_verts.append(v2)
		flat_normals.append(normal)
		flat_normals.append(normal)
		flat_normals.append(normal)
	

	var new_arrays := []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = flat_verts
	new_arrays[Mesh.ARRAY_NORMAL] = flat_normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)

	terrain_node.mesh = mesh
	terrain_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
