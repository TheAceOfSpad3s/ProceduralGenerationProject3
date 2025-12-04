extends Control

@onready var score_text = $ScoreText
@onready var options_menu = $OptionsMenu
@onready var pause_menu = $PauseMenu
@onready var retry_menu = $RetryMenu
@onready var final_score_text = $RetryMenu/FinalScore
@onready var leader_board = $LeaderBoard
@onready var transition = $Transition

signal Transition(reverse: bool)

var paused = false
var game_over = false

func _on_score_manager_score_updated(score):
	score_text.text = "Score: " + str(score)



func _ready():
	pause_menu.hide()
	options_menu.hide()
	retry_menu.hide()
	leader_board.hide()
	Transition.emit(true)
func _process(_delta):
	if game_over:
		return
	if Input.is_action_just_pressed("pause"):
		if not paused:
			Engine.time_scale = 0
			pause_menu.show()
			paused = true
		else:
			Engine.time_scale = 1
			pause_menu.hide()
			options_menu.hide()
			paused = false
		


func _on_resume_pressed():
			Engine.time_scale = 1
			pause_menu.hide()
			paused = false

func _on_options_pressed():
	if not game_over:
		pause_menu.hide()
	else:
		leader_board.hide()
		retry_menu.hide()
	options_menu.show()

func _on_quit_pressed():
	Engine.time_scale = 0.01
	await get_tree().create_timer(0.002).timeout
	get_tree().quit()


func _on_back_pressed():
	if not game_over:
		pause_menu.show()
	else:
		leader_board.show()
		retry_menu.show()
	options_menu.hide()
	
	


func _on_back_mouse_entered():
	$OptionsMenu/Back/RichTextLabel.text = "[color=#000000]X[/color]"


func _on_back_mouse_exited():
	$OptionsMenu/Back/RichTextLabel.text = "X"




func _on_score_manager_final_score(final_score):
	print(final_score)
	final_score_text.text = "[center]Score: " + str(final_score) + "[/center]"


func _on_main_game_over():
	retry_menu.show()
	score_text.hide()
	game_over = true
	leader_board.show()
func _on_play_again_pressed():
	Transition.emit(false)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/intro.tscn")



	
