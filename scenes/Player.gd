extends CharacterBody3D

# --- Properties for tuning ---
@export var horizontal_speed := 10.0
@export var vertical_speed := 10.0
@export var roll_speed := 20.0
@export var bank_rotation_speed := 5.0
enum State {DEFUALT, ROLLING, DEAD}
enum CameraState {Mountain, Ravine}
signal Player_Dead
signal CurrentHeight
signal AddScore
var currentState : State = State.DEFUALT
var currentCameraState: CameraState = CameraState.Mountain
var camerafov = 110.0 if currentCameraState == CameraState.Mountain else 60.0
# The nodes we need references to.
@onready var roll_timer = $RollTimer
@onready var roll_cooldown = $RollCooldown
@onready var camera_controller = $CameraController
@onready var camera_target = $CameraController/CameraTarget
@onready var camera = $CameraController/CameraTarget/PlayerCamera
@onready var death_camera = $CameraController/CameraTarget/DeathCamera
@onready var graze_cooldown =$Graze/GrazeCooldown
# Consts
const BANK_AMOUNT = PI/10.0
var roll_x_direction = 0.0
var angular_velocity: float = 0.0
var can_graze = true

func _physics_process(delta: float) -> void:
	if currentState == State.DEAD:
		camera_controller.position  = lerp(camera_controller.position,position - death_camera.position, 0.05)
		camera_target.rotation = lerp(camera_target.rotation, death_camera.rotation, delta*3.0)
		#In Order To Stop all Player Code(IMPORTANT)
		return
		
	var input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if Input.is_action_just_pressed("roll") and roll_cooldown.time_left == 0 and input_direction.x != 0:
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
		var target_rotation = Vector3(0,PI,0)
		
		# If we're turning left or right, we want to rotate on the Z-axis.
		target_rotation.z = input_direction.x * BANK_AMOUNT
		# If we're moving up or down, we want to rotate on the X-axis.
		target_rotation.x = input_direction.y * BANK_AMOUNT
		rotation = rotation.lerp(target_rotation, delta * bank_rotation_speed)

	if currentState == State.ROLLING:
		var elapsed_time = roll_timer.wait_time - roll_timer.time_left
		rotation.z = angular_velocity * elapsed_time 
		
		velocity.x = roll_x_direction* roll_speed
	# This function handles all movement and physics collisions for us!
	if move_and_slide():
		var collision = get_slide_collision(0)
		if collision:
			# If we collide with something, change the state to DEAD
			Player_Dead.emit()
			print("Collision detected!")
	
		
	#Match Camera Controller Match the positon of myself
	var lerp_speed = 0.25 if currentCameraState == CameraState.Mountain else 0.5
	camera_controller.position  = lerp(camera_controller.position,position,lerp_speed)
	#Changing Settings of Camera based on Chunk Type
	var target_fov = 100.0 if currentCameraState == CameraState.Mountain else 65.0
	camera.fov = lerp(camera.fov, target_fov, delta * 3.0)
	var target_positon_camera = Vector3(0,0.784,1.635) if currentCameraState == CameraState.Mountain else Vector3(0,0.418,1.56)
	camera_target.position = lerp(camera_target.position,target_positon_camera, delta*3.0)
	var target_rotation_camera = Vector3(deg_to_rad(22.9),-PI,0) if currentCameraState == CameraState.Mountain else Vector3(deg_to_rad(10),-PI,0)
	camera_target.rotation = lerp(camera_target.rotation, target_rotation_camera, delta*3.0)
	CurrentHeight.emit(position.y)

func _on_roll_timer_timeout():
	roll_timer.stop()
	
	if currentState != State.DEAD:
		currentState = State.DEFUALT


func _on_chunk_manager_chunk_type(chunk_type):
	if chunk_type == 0:
		currentCameraState = CameraState.Mountain
	elif  chunk_type == 1:
		currentCameraState = CameraState.Ravine



func _on_main_game_over():
	currentState = State.DEAD


func _on_area_3d_body_entered(_body):
	if currentState != State.DEAD and can_graze:
		print("Body Entered")
		AddScore.emit()
		can_graze = false
		graze_cooldown.start()


func _on_graze_cooldown_timeout():
	can_graze = true
