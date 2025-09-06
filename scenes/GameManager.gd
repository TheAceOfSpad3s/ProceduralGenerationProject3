extends Node3D

signal StartGame()
signal GameOver()


func _on_player_player_dead():
	GameOver.emit()
