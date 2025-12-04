extends Control

# Signals to communicate success (bool) and the overlap percentage (float)
signal qte_result(success, percentage)

# Speed of the marker (Units per second). This will be adjusted per launch stage.
var current_speed: float = 300.0
var current_duration: float = 10.0
var current_size: float = 40.0
# --- Node References ---
@onready var background = $bar
@onready var marker = $bar/marker
@onready var qte_timer = $qte_timer
# Note: Using $"bar/target zone" assumes your green block node is named "target zone" with a space.
@onready var target_zone = $"bar/target zone" 

# --- State ---
var is_active: bool = false
var direction: int = 1 # 1 = moving down, -1 = moving up
enum HitType{Miss, Weak_Hit, Strong_Hit, Perfect_Hit}
var current_hit = HitType.Miss
# --- Target Zone Positioning ---

# New function to set the target zone to a random, valid Y position
func _set_random_target_position(target_height: float):
	# 1. Get the vertical dimensions of the container and the zone
	var bar_height = background.size.y
	var zone_height = target_height
	
	# 2. Calculate the maximum valid Y position. 
	# The top of the target zone can be no lower than (Bar Height - Zone Height)
	var max_y_position = bar_height - zone_height
	
	# 3. Choose a random float value between 0 (top) and max_y_position (bottom limit)
	var random_y = randf_range(0.0, max_y_position)
	
	# 4. Apply the new position (keeping the X position the same)
	target_zone.position = Vector2(target_zone.position.x, random_y)
	target_zone.size.y = zone_height

# --- Initialization and Start ---
func start_qte(duration: float, new_speed: float, target_height: float):
	current_speed = new_speed
	current_duration = duration
	current_size = target_height
	qte_timer.wait_time = current_duration
	qte_timer.start()
	qte_timer.one_shot = true
	is_active = true
	visible = true
	background.show()
	# CRITICAL: Set the target zone position before starting the movement!
	_set_random_target_position(target_height)
	
	# Set marker starting position at the bottom of the bar
	marker.position = Vector2(marker.position.x, background.size.y - marker.size.y) 
	direction = -1 # Start moving UP towards 0 (top)

# --- Game Loop (The movement happens here) ---
func _process(delta: float):
	if not is_active:
		return

	# Calculate vertical movement based on speed, direction, and time
	var move_amount = current_speed * direction * delta
	var new_y = marker.position.y + move_amount
	
	var min_y = 0 # Top of the bar
	var max_y = background.size.y - marker.size.y # Bottom of the bar
	
	# Apply new position
	marker.position = Vector2(marker.position.x, new_y)
	
	# Bounce logic (if it hits the top or bottom, reverse direction)
	if new_y <= min_y:
		direction = 1 # Move down
		marker.position = Vector2(marker.position.x, min_y)
	elif new_y >= max_y:
		direction = -1 # Move up
		marker.position = Vector2(marker.position.x, max_y)


# --- Timeout Handling (If the player runs out of time) ---
func _on_qte_timer_timeout():
	if is_active:
		is_active = false
		print("QTE FAILED: Time ran out!")
		# Emit false and 0.0 percentage
		qte_result.emit(false, 0.0)
		
		background.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		background.modulate = Color.WHITE

func _ready():
	start_qte(10.0, 300.0, 65.0)
# --- Input Handling ---
func _input(event):
	if is_active and event.is_action_pressed("qte_accept"): 
		check_qte_success()
		get_viewport().set_input_as_handled()

# --- Core Logic: Calculate Overlap and Determine Success ---
func check_qte_success():
	# Stop movement and timer
	is_active = false
	qte_timer.stop()
	
	# 1. Define Boundaries
	var marker_y_top = marker.position.y
	var marker_y_bottom = marker.position.y + marker.size.y
	var target_y_top = target_zone.position.y
	var target_y_bottom = target_zone.position.y + target_zone.size.y
	
	# 2. Calculate Overlap Length
	
	# The start of the overlap is the lowest Y coordinate of the two top edges.
	var overlap_start = max(marker_y_top, target_y_top)
	
	# The end of the overlap is the highest Y coordinate of the two bottom edges.
	var overlap_end = min(marker_y_bottom, target_y_bottom)
	
	# The length of the overlap must be 0 or positive. If they don't overlap, this is 0.
	var overlap_length = max(0.0, overlap_end - overlap_start)
	
	# 3. Calculate Percentage and Success
	
	# Percentage is the overlap length divided by the marker's total height.
	var overlap_percentage = overlap_length / marker.size.y * 100
	
	# Success is defined as any percentage greater than 0.
	var success = overlap_percentage > 50
	if success:
		background.modulate = Color.GREEN
		if overlap_percentage < 70:
			current_hit = HitType.Weak_Hit
		elif overlap_percentage < 100:
			current_hit = HitType.Strong_Hit
		elif overlap_percentage == 100:
			current_hit = HitType.Perfect_Hit
		await get_tree().create_timer(0.4).timeout
		background.hide()
	else:
		background.modulate = Color.RED
		current_hit = HitType.Miss
		start_qte(current_duration, current_speed, current_size)
	# 4. Feedback and Signal
	
	var _percentage_text = str(snapped(overlap_percentage * 100.0, 0.1)) + "%"
	
	#print("QTE Attempt | Overlap: ", _percentage_text, " | Success: ", success)
	#print(HitType.find_key(current_hit))
	# Emit the result (success status AND the percentage)
	qte_result.emit(success, overlap_percentage)

	await get_tree().create_timer(0.2).timeout
	background.modulate = Color.WHITE


func _on_jet_start_qte_bar(duration, new_speed, target_height):
	start_qte(duration, new_speed, target_height)
