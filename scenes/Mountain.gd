extends Node3D

@export var mountain_width := 120.0 # The central, noisy width
@export var side_padding_width := 100.0 # Total flat space added to each side (barrier + taper)
@export var taper_distance := 5.0 # How far the height will slope downwards before becoming flat
@export var mountain_length := 10.0
@export var subdivisions_x := 40 # High detail for the main mountain
@export var side_subdivisions_x := 5 # Low detail for the flat side padding (LOWER FPS LOAD)
@export var subdivisions_z := 5
@export var height_scale : float = 5.0
@export var min_height_scale: float = 1.0 # This now controls the flat edge height
@export var max_height_scale: float = 20.0
@export var noise_scale := 0.24

var noise: FastNoiseLite = null
var mountain_id: int = 0
var shader: ShaderMaterial = preload("res://Shaders/TerrainShader.tres")
@onready var timer = $Mountain_Timer
var height_inc = false

func set_noise_reference(shared_noise: FastNoiseLite) -> void:
	noise = shared_noise

func generate_mesh(world_z_offset: float) -> void:
	if noise == null:
		push_error("mountain.generate_mesh: noise is null — call set_noise_reference(shared_noise) first.")
		return
		
	if timer.time_left > 10:
		position.y = -height_scale/2

	# --- PADDING AND MESH SIZE SETUP ---
	var _total_mesh_width = mountain_width + (side_padding_width * 2.0)
	
	# Global X-coordinate where the mountain noise ends and the taper begins.
	var mountain_x_edge = mountain_width / 2.0
	
	# Global X-coordinate where the taper ends and the terrain becomes completely flat.
	var flat_x_edge = mountain_x_edge + taper_distance
	
	# Ensure the taper distance isn't larger than the padding width
	taper_distance = min(taper_distance, side_padding_width)

	# --- 1. CREATE THREE SEPARATE PLANE MESHES ---
	var center_plane = PlaneMesh.new()
	center_plane.size = Vector2(mountain_width, mountain_length)
	center_plane.subdivide_width = subdivisions_x
	center_plane.subdivide_depth = subdivisions_z
	
	var side_plane = PlaneMesh.new()
	side_plane.size = Vector2(side_padding_width, mountain_length)
	side_plane.subdivide_width = side_subdivisions_x # Low detail for the sides!
	side_plane.subdivide_depth = subdivisions_z
	
	# --- 2. COMPILE ALL VERTICES AND INDICES ---
	
	# Calculate global offsets for each plane's center
	var left_offset = -(mountain_width / 2.0) - (side_padding_width / 2.0)
	var center_offset = 0.0
	var right_offset = (mountain_width / 2.0) + (side_padding_width / 2.0)
	
	var all_verts: PackedVector3Array = []
	var all_indices: PackedInt32Array = []
	
	# --- Left Plane Data (Offset: left_offset) ---
	var left_arrays = side_plane.surface_get_arrays(0)
	_process_plane_section(left_arrays, left_offset, world_z_offset, mountain_x_edge, flat_x_edge, all_verts, all_indices)

	# --- Center Plane Data (Offset: center_offset) ---
	var center_arrays = center_plane.surface_get_arrays(0)
	_process_plane_section(center_arrays, center_offset, world_z_offset, mountain_x_edge, flat_x_edge, all_verts, all_indices)

	# --- Right Plane Data (Offset: right_offset) ---
	var right_arrays = side_plane.surface_get_arrays(0) # Reuse the low detail plane for the right side
	_process_plane_section(right_arrays, right_offset, world_z_offset, mountain_x_edge, flat_x_edge, all_verts, all_indices)

	# --- 3. REBUILD THE MESH WITH FLAT SHADING ---

	var flat_verts := PackedVector3Array()
	var flat_normals := PackedVector3Array()

	for i in range(0, all_indices.size(), 3):
		# Get the triangle vertices from the combined list
		var v0 = all_verts[all_indices[i]]
		var v1 = all_verts[all_indices[i + 1]]
		var v2 = all_verts[all_indices[i + 2]]
		
		# Calculate flat normal
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

# Helper function to process one section (left, center, or right)
func _process_plane_section(arrays: Array, x_offset: float, world_z_offset: float, mountain_x_edge: float, flat_x_edge: float, all_verts: PackedVector3Array, all_indices: PackedInt32Array) -> void:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var vert_index_base = all_verts.size() # Start index in the global vertex array

	for i in range(verts.size()):
		var v = verts[i]
		
		# --- 1. Translate the vertex to its correct global X position ---
		var global_x = v.x + x_offset
		var x_abs = abs(global_x)
		
		# 2. Calculate the base noise height (using global_x for continuous noise)
		var noise_h = noise.get_noise_2d(global_x * noise_scale, (world_z_offset + v.z) * noise_scale) * height_scale
		
		var target_flat_height = min_height_scale
		# Subtle noise offset for the edges (prevents being perfectly flat)
		var slight_noise = noise.get_noise_2d(global_x * noise_scale * 0.5, (world_z_offset + v.z) * noise_scale * 0.5) * (min_height_scale * 0.1)

		if x_abs <= mountain_x_edge:
			# Case 1: Central Area (Full Noise)
			v.y = noise_h
		elif x_abs > mountain_x_edge and x_abs < flat_x_edge:
			# Case 2: Tapering Zone (Sloping Downwards)
			var t = (x_abs - mountain_x_edge) / taper_distance
			
			# Smoothly transition from mountain noise to the dynamic minimum height + slight noise
			v.y = lerp(noise_h, target_flat_height + slight_noise, t)
		else:
			# Case 3: Flat Edge (Barrier)
			v.y = target_flat_height + slight_noise
		
		# Update the vertex's X position to its global, translated position for the combined mesh
		v.x = global_x
		
		all_verts.append(v)

	# --- 3. Append indices, adjusting for the new base index ---
	for i in indices:
		all_indices.append(i + vert_index_base)

func _physics_process(_delta):
	# The position.y adjustment here uses height_scale, which is what the user controls
	if height_inc:
		var height_speed = 0.004 if height_scale < 10 else 0.004
		height_scale = lerp(height_scale, max_height_scale, height_speed)
	elif not height_inc:
		var height_speed = 0.002 if height_scale < 10 else 0.004
		height_scale = lerp(height_scale, min_height_scale, height_speed)


func _on_mountain_timer_timeout():
	height_inc = false


func _on_mountain_inc_timer_timeout():
	height_inc = true
