# CameraFollow.gd
# This script makes the camera smoothly follow a target node.
extends Camera3D

# The node to follow, which should be the player.
# You will set this in the Inspector after adding the script to the Camera3D node.
@export var target: Node3D

# The distance the camera should stay behind the target.
@export var follow_distance = 5.0

# How quickly the camera moves to catch up to the target.
# A lower value means a slower, more "laggy" follow.
@export var lerp_speed = 10.0

# The height offset of the camera relative to the target.
@export var height_offset = 0.5


func _process(delta: float) -> void:
	# Ensure there is a target to follow
	if not is_instance_valid(target):
		return
	
	# Get the target's position
	var target_position = target.global_position
	
	# Calculate the desired position of the camera
	# This position is behind the target, at the specified distance and height
	var desired_position = target_position + Vector3(0, height_offset, follow_distance)
	
	# Smoothly move the camera toward the desired position
	global_position = global_position.lerp(desired_position, lerp_speed * delta)
	
	# Make the camera look at the target to keep it centered
	look_at(target_position, Vector3.UP)
