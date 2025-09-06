extends Control


func _on_score_manager_score_updated(score):
	$RichTextLabel.text = "Score: " + str(score)
