extends Node3D

# --- New Export Variables ---
@export var transition_duration: float = 4.0 # How long the sky fade and rotation animation takes

# --- Color Definitions (Used in the state list below) ---
@export var morningColorTop: Color = Color("5897fa")
@export var morningColorHorizon: Color = Color("d3916b")

@export var dayColorTop: Color = Color("1f6ddf")
@export var dayColorHorizon: Color = Color("56a9f5")

@export var afternoonColorTop: Color = Color("3d6fcd")
@export var afternoonColorHorizon: Color = Color("e98174")

@export var nightColorTop: Color = Color("090e14")
@export var nightColorHorizon: Color = Color("010049")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun = $Sun # Assumes you have a Node3D named 'Sun' that parents your DirectionalLight3D

# --- State Management ---
var currentDayState: int = 0
var dayStates: Array = [] # Stores all color data and sun rotation
var adjust_sun = false
func _ready() -> void:
	# 1. Define the four distinct states with colors AND sun rotation X
	# Note: These rotation degrees are examples. You might need to tweak them (e.g., use negative values)
	# depending on how your $Sun node is oriented in the scene. 0 degrees is typically overhead.
	dayStates = [
		# Sun at about 45 degrees, coming up
		{"name": "Morning", "top": morningColorTop, "horizon": morningColorHorizon, "transition_sun_rotation_x": deg_to_rad(180.0)},
		
		# Sun directly overhead
		{"name": "Day", "top": dayColorTop, "horizon": dayColorHorizon, "transition_sun_rotation_x": deg_to_rad(225.0)}, 
		
		# Sun at about 45 degrees, going down
		{"name": "Afternoon", "top": afternoonColorTop, "horizon": afternoonColorHorizon, "transition_sun_rotation_x": deg_to_rad(180.0)},
		
		# Sun completely down (below world)
		{"name": "Night", "top": nightColorTop, "horizon": nightColorHorizon, "transition_sun_rotation_x": deg_to_rad(0.0)} 
	]
	
	# 2. Set the initial state immediately (Morning)
	_set_initial_state()

# Sets the environment instantly without transition
func _set_initial_state():
	# Apply the first state (Morning) instantly
	currentDayState = 0
	_apply_state(currentDayState, 0.0) # Duration 0.0 for instant application

# Transitions the environment to the next state in the sequence
func _transition_to_next_state():
	# 1. Calculate the index of the next state (wraps around 0-3)
	currentDayState = (currentDayState + 1) % dayStates.size()
	
	# 2. Apply the colors and sun position with a smooth transition
	_apply_state(currentDayState, transition_duration)

# Helper function to apply colors and set the sun rotation
func _apply_state(state_index: int, duration: float):
	var state_data = dayStates[state_index]
	var topColor = state_data.top
	var horizonColor = state_data.horizon
	var sunRotationX = rad_to_deg(state_data.transition_sun_rotation_x)# Target rotation for the sun

		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	# --- Tween Sky Colors ---
	tween.tween_property(world_environment, "environment:sky:sky_material:sky_top_color", topColor, duration)
	tween.parallel()
	tween.tween_property(world_environment, "environment:sky:sky_material:sky_horizon_color", horizonColor, duration)
	
	# --- Tween Ground Colors ---
	tween.parallel()
	tween.tween_property(world_environment, "environment:sky:sky_material:ground_bottom_color", topColor, duration)
	tween.parallel()
	tween.tween_property(world_environment, "environment:sky:sky_material:ground_horizon_color", horizonColor, duration)

	# --- Tween Sun Rotation ---
	if sun:
		tween.parallel()
		# Tween the sun's X rotation directly using degrees
		tween.tween_property(sun, "rotation_degrees:x", sunRotationX, duration)
	
	print("World transitioning to state: ", state_data.name)
	
	if currentDayState == 3:
		world_environment.environment.fog_enabled = false
	else:
		world_environment.environment.fog_enabled = true


# --- Signal Handler ---

# This function is called every time ChunkManager emits its signal
func _on_chunk_manager_day_night_cycle():
	_transition_to_next_state()
	

func _on_chunk_manager_chunk_type(chunk_type):
	if adjust_sun:
		if chunk_type == 0:
			world_environment.environment.fog_density = 0.015
			if currentDayState == 1:
				sun.rotation.x = deg_to_rad(200.0)
		elif chunk_type == 1:
			world_environment.environment.fog_density = 0.01
			if currentDayState == 1:
				sun.rotation.x = deg_to_rad(195.0)
	adjust_sun = true


	
func _on_chunk_manager_fog_activation(_is_showing, _fog_speed, _fog_offset):
	if world_environment.environment.volumetric_fog_sky_affect == 1:
		world_environment.environment.volumetric_fog_sky_affect = 0
	else:
		world_environment.environment.volumetric_fog_sky_affect = 1




func _on_main_game_over():
	world_environment.environment.volumetric_fog_enabled = false
