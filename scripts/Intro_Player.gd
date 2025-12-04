extends CharacterBody3D

@onready var engine_left = $JetModel/EngineLeft
@onready var engine_right = $JetModel/EngineRight
@onready var jet_model = $JetModel
@onready var wheels_retracting_animation = $JetModel/legs/wheels_retracting_animation
@onready var trail_left = $JetModel/TrailLeft
@onready var trail_right = $JetModel/TrailRight
@onready var camera_3d = $JetModel/Camera/Camera3D
@onready var jet_impact_frame_animation = $JetModel/jet_impact_frame_animation
@onready var camera_impact_animation = $JetModel/Camera/camera_impact_animation


var hit_count = 1
var is_flying = false

var initial_rotation_x = deg_to_rad(-11.6)
var final_rotation_x = deg_to_rad(-25.0)

signal Start_QTE_Bar(duration: float, new_speed: float, target_height: float)
signal ScreenShake(intensity: float, reduction_rate: float)
signal Transition(reverse: bool)
func _ready():
	randomize()
	jet_model.rotation.x = initial_rotation_x
	engine_left.hide()
	engine_right.hide()
	trail_left.hide()
	trail_right.hide()
	Transition.emit(true)
	#Start_QTE_Bar.emit(10.0, 300.0, 40.0)


func _physics_process(delta):
	if is_flying:
		jet_model.rotation.x = lerp(jet_model.rotation.x, final_rotation_x, delta*2.0)
	else:
		jet_model.rotation.x = lerp(jet_model.rotation.x, initial_rotation_x, delta*2.0)
	move_and_slide()



func _on_qte_bar_qte_result(success, _percentage):
	if success:
		if hit_count == 1:
			velocity.z = 1
			engine_left.show()
			engine_right.show()
			ScreenShake.emit(0.5, 5.0)
			hit_count += 1
			await get_tree().create_timer(1.0).timeout
			Start_QTE_Bar.emit(10.0, 300.0, 55.0)
		elif hit_count == 2:
			velocity.z = 3.0
			hit_count += 1
			ScreenShake.emit(1.0, 4.5)
			
		elif hit_count == 3:
			ScreenShake.emit(50.0, 1.0)
			#var camera_transform = camera_3d.global_transform

			#var scene_root = get_parent()
			#camera_3d.reparent(scene_root)
			#camera_3d.global_transform = camera_transform
			velocity.z = 0.0
			#jet_impact_frame_animation.play("jet_impact_frame_animation")
			#camera_impact_animation.play("camera_impact_animation")
			await get_tree().create_timer(0.5).timeout
			velocity.z = 100.0
			await get_tree().create_timer(0.3).timeout
			Transition.emit(false)
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_flying_checkpoint_area_entered(_area):
	is_flying = true
	velocity.z = 7.0
	velocity.y = 0.8
	trail_left.show()
	trail_right.show()
	await get_tree().create_timer(2.0).timeout
	is_flying = false
	wheels_retracting_animation.play("wheels_retracting")
	await get_tree().create_timer(0.5).timeout
	Start_QTE_Bar.emit(3.0, 320.0, 50.0) # Assuming the final QTE should start here
	# Removed the QTE start here, assuming it's managed by hit_count 1 & 2
