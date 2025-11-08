extends Node3D

signal ScoreUpdated(score: int)
signal FinalScore(score: int)
var is_scoring = true
var score : float = 0.0
var player_current_height : float = 0.0

var safe_height: float = 7.0
var height_score_multiplier: float = 5.0
var graze_bonus : float = 1000.0
var chunk_clear_bonus: float = 2000.0


func _on_player_current_height(current_height):
	player_current_height = current_height


func _on_score_timer_timeout():
	if is_scoring:
		if player_current_height < 0:
			score += -player_current_height * height_score_multiplier
		elif player_current_height >= 0 and player_current_height < safe_height:
			score += safe_height - player_current_height  
		var rounded_score = max(0.0, round(score / 5.0) * 5.0)               
		ScoreUpdated.emit(rounded_score)


func _on_main_game_over():
	is_scoring = false
	var rounded_score = max(0.0, round(score / 5.0) * 5.0)  
	FinalScore.emit(rounded_score)

func _on_chunk_manager_is_scoring():
	is_scoring = not is_scoring




func _on_player_add_score():
	if is_scoring:
		score += graze_bonus
		ScoreUpdated.emit(round(score))


func _on_chunk_manager_add_chunk_clear_score():
	if is_scoring:
		score += chunk_clear_bonus
		ScoreUpdated.emit(round(score))
