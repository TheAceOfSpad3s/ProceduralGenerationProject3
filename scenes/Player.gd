extends CharacterBody3D

# --- Properties for tuning ---
@export var horizontal_speed := 1.0
@export var vertical_speed := 1.0
@export var roll_speed := 5.0
@export var bank_rotation_speed := 5.0
enum State {DEFUALT, ROLLING, DEAD}


var currentState : State = State.DEFUALT
# The nodes we need references to.
@onready var jet_model = $JetModel
@onready var roll_timer = $RollTimer
@onready var roll_cooldown = $RollCooldown

# Consts
const BANK_AMOUNT = PI/10.0
var roll_x_direction = 0.0
var angular_velocity: float = 0.0


func _physics_process(delta: float) -> void:
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if Input.is_action_just_pressed("roll") and roll_cooldown.time_left == 0 and input_direction.x != 0 :
		roll_timer.start()
		roll_cooldown.start()
		angular_velocity = TAU/roll_timer.wait_time * input_direction.x
		roll_x_direction = input_direction.x
		currentState = State.ROLLING
	if currentState == State.DEFUALT:
		# --- 1. Get User Input ---
		# We'll use a single Vector2 to store horizontal and vertical input.

		# --- 2. Calculate Velocity ---
		velocity.x = input_direction.x * horizontal_speed
		velocity.y = -input_direction.y * vertical_speed

		# --- 3. Smooth the Rotation
		var target_rotation = Vector3.ZERO
		
		# If we're turning left or right, we want to rotate on the Z-axis.
		target_rotation.z = input_direction.x * BANK_AMOUNT
		# If we're moving up or down, we want to rotate on the X-axis.
		target_rotation.x = input_direction.y * BANK_AMOUNT
		jet_model.rotation = jet_model.rotation.lerp(target_rotation, delta * bank_rotation_speed)

	if currentState == State.ROLLING:
		var elapsed_time = roll_timer.wait_time - roll_timer.time_left
		jet_model.rotation.z = angular_velocity * elapsed_time 
		
		velocity.x = roll_x_direction* roll_speed
	# This function handles all movement and physics collisions for us!
	move_and_slide()



func _on_roll_timer_timeout():
	roll_timer.stop()
	jet_model.rotation = Vector3.ZERO
	currentState = State.DEFUALT
