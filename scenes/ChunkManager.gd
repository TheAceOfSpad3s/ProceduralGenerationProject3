# ChunkManager.gd
extends Node3D

# Common
@export var num_chunks := 5
@export var speed := 40.0 # world moves toward player (units/sec)
@export var initial_spawn_offset := -100.0 # New variable to control how far back chunks spawn

@onready var fog_timer = $FogTimer
@onready var chunk_timer = $ChunkTimer

signal chunk_type

var time_until_next_recycle: float = 0.0
var recycle_threshold: float = 0.0
var is_transitioning: bool = false
var normal_fog_depth: float = 0.0
var player_dead = false
# Ravine
@export var ravine_scenes: Array[PackedScene] = []
@export var ravine_frequency: float = 0.05
@export var ravine_noise_fractal_octaves: int = 4
@export var ravine_length := 50.0
var ravines: Array = []
var next_ravine_id: int = 0
var ravine_noise := FastNoiseLite.new()

# Mountain
@export var mountain_scenes: Array[PackedScene] = []
@export var mountain_frequency: float = 0.1
@export var mountain_noise_fractal_octaves: int = 4
@export var mountain_length := 50.0
var mountains: Array = []
var next_mountain_id: int = 0
var mountain_noise := FastNoiseLite.new()

# New: A single variable to hold the currently selected scene
var current_scene: PackedScene

# New: A single variable to hold the active chunks (either mountains or ravines)
var active_chunks: Array = []
var last_chunk_position_z: float = 0.0
var next_id: int = 0

enum Chunk_Type {Mountains, Ravines}
var current_chunk_type: Chunk_Type = Chunk_Type.Mountains

func _ready() -> void:
	assert(not ravine_scenes.is_empty(), "Add at least one Ravine.tscn to ravine_scenes.")
	assert(not mountain_scenes.is_empty(), "Add at least one Mountain.tscn to mountain_scenes.")
	
	# Store the initial fog depth so we can return to it after the transition
	
	# Initialize the noise, but don't set the seed yet, that happens in _choose_current_scene
	ravine_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ravine_noise.frequency = ravine_frequency
	ravine_noise.fractal_octaves = ravine_noise_fractal_octaves
	
	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_noise.frequency = mountain_frequency
	mountain_noise.fractal_octaves = mountain_noise_fractal_octaves
	
	# Initial setup of chunks
	_choose_current_scene()
	_instantiate_chunks()
	
	recycle_threshold = ravine_length / speed


# New: Chooses the next scene and sets up the active_chunks array
func _choose_current_scene():
	var use_mountains = randi() % 2 == 0
	
	if use_mountains:
		current_chunk_type = Chunk_Type.Mountains
		var random_index = randi() % mountain_scenes.size()
		current_scene = mountain_scenes[random_index]
		# Re-seed the noise generator for a new pattern
		mountain_noise.seed = randi()
	else:
		current_chunk_type = Chunk_Type.Ravines
		var random_index = randi() % ravine_scenes.size()
		current_scene = ravine_scenes[random_index]
		# Re-seed the noise generator for a new pattern
		ravine_noise.seed = randi()

	# Reset the chunk spawn position and ID, and apply the initial offset
	last_chunk_position_z = initial_spawn_offset
	next_id = 0
	chunk_type.emit(current_chunk_type)
	
# New: A unified function to instantiate chunks based on the current scene
func _instantiate_chunks():
	for i in range(num_chunks):
		_spawn_next_chunk()

# New: A unified function to spawn and recycle chunks
func _spawn_next_chunk():
	var new_chunk = current_scene.instantiate()
	add_child(new_chunk)
	
	var chunk_length = 0
	var noise_ref = null
	var y_pos = 0.0
	
	if current_chunk_type == Chunk_Type.Mountains:
		chunk_length = mountain_length
		noise_ref = mountain_noise
		y_pos = 0.0
	else:
		chunk_length = ravine_length
		noise_ref = ravine_noise
		y_pos = 10.0
	
	new_chunk.set_noise_reference(noise_ref)
	new_chunk.position = Vector3(0, y_pos, last_chunk_position_z - chunk_length)
	
	# Pass the correct ID and position for mesh generation
	if current_chunk_type == Chunk_Type.Mountains:
		new_chunk.mountain_id = next_id
		new_chunk.generate_mesh(-new_chunk.mountain_id * mountain_length)
	else:
		new_chunk.ravine_id = next_id
		new_chunk.generate_mesh(-new_chunk.ravine_id * ravine_length)
	
	active_chunks.append(new_chunk)
	last_chunk_position_z = new_chunk.position.z
	next_id += 1


func _process(delta: float) -> void:
	if player_dead:
		return
	
	# Move all active chunks regardless of type
	for chunk in active_chunks:
		chunk.position.z += speed * delta
		
	if not is_transitioning:
		# Recycle logic is now unified
		if active_chunks.size() > 0:
			var first_chunk = active_chunks[0]
			var chunk_length = mountain_length if current_chunk_type == Chunk_Type.Mountains else ravine_length
			
			if first_chunk.position.z >= chunk_length:
				# Recycle the chunk
				var recycled_chunk = active_chunks.pop_front()
				var last_chunk = active_chunks.back()
				
				var y_pos = 0.0
				var noise_ref = null
				if current_chunk_type == Chunk_Type.Mountains:
					y_pos = 0.0
					noise_ref = mountain_noise
				else:
					y_pos = 10.0
					noise_ref = ravine_noise
				
				recycled_chunk.position = Vector3(0, y_pos, last_chunk.position.z - chunk_length)
				recycled_chunk.set_noise_reference(noise_ref)
				
				if current_chunk_type == Chunk_Type.Mountains:
					recycled_chunk.mountain_id = next_id
					recycled_chunk.generate_mesh(-recycled_chunk.mountain_id * mountain_length)
				else:
					recycled_chunk.ravine_id = next_id
					recycled_chunk.generate_mesh(-recycled_chunk.ravine_id * ravine_length)
					
				next_id += 1
				active_chunks.append(recycled_chunk)
				
				# Call _choose_current_scene() when you want to switch
				# You can connect a timer to this function to handle the switching
	else:
		if active_chunks.size() > 0:
			var first_chunk = active_chunks[0]
			var chunk_length = mountain_length if current_chunk_type == Chunk_Type.Mountains else ravine_length
			if first_chunk.position.z >= chunk_length:
				first_chunk.queue_free()
				active_chunks.pop_front()


func _on_chunk_timer_timeout():
	chunk_timer.stop()
	is_transitioning = true
	# Tween the fog to become thick and opaque
	# Corrected property access to go through the `environment` resource
	fog_timer.start()
func _on_fog_timer_timeout():
	fog_timer.stop()
	_choose_current_scene()
	is_transitioning = false
	chunk_timer.start()
	_instantiate_chunks()


func _on_player_player_dead():
	player_dead = true
