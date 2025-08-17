# ChunkManager.gd
extends Node3D

@export var ravine_scene: PackedScene # New export for the ravine scene
@export var num_chunks := 5
@export var ravine_length := 50.0
@export var speed := 40.0 # world moves toward player (units/sec)

# Noise configuration variables
@export var ravine_frequency: float = 0.05
@export var noise_fractal_octaves: int = 4

var ravines: Array = [] # New array to hold the ravine instances
var next_ravine_id: int = 0
var ravine_noise := FastNoiseLite.new() # The new noise function for carving

var time_until_next_recycle: float = 0.0
var recycle_threshold: float = 0.0

func _ready() -> void:
	assert(ravine_scene != null, "Assign Ravine.tscn to ravine_scene in the inspector.")

	# Configure the ravine noise
	ravine_noise.seed = randi()
	ravine_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ravine_noise.frequency = ravine_frequency
	ravine_noise.fractal_octaves = noise_fractal_octaves

	for i in range(num_chunks):
		# Instantiate and configure the ravine
		var r = ravine_scene.instantiate()
		add_child(r)
		r.set_noise_reference(ravine_noise)
		r.ravine_id = i
		r.position = Vector3(0, 0, -r.ravine_id * ravine_length)
		r.generate_mesh(r.position.z)
		ravines.append(r)
	
	next_ravine_id = num_chunks
	
	# Set the initial timer and threshold
	recycle_threshold = ravine_length / speed
	time_until_next_recycle = recycle_threshold

func _process(delta: float) -> void:
	# Move all ravines
	for r in ravines:
		r.position.z += speed * delta
		
	time_until_next_recycle -= delta
	
	if ravines.size() > 0 and ravines[0].position.z >= ravine_length:
		# Recycle the ravine
		var recycled_ravine = ravines.pop_front()
		var last_ravine = ravines.back()
		
		recycled_ravine.ravine_id = next_ravine_id
		next_ravine_id += 1
		recycled_ravine.position = Vector3(0, 0, last_ravine.position.z - ravine_length)
		
		recycled_ravine.generate_mesh(-recycled_ravine.ravine_id * ravine_length)
		
		ravines.append(recycled_ravine)
