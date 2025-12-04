extends Control



func _on_jet_transition(reverse):
	self.show()
	if not reverse:
		$transition_animation.play("transition_animation")
	if reverse:
		$transition_animation.play("transition_animation", -1,-1.0, true)
		


func _on_ui_manager_transition(reverse):
	self.show()
	if not reverse:
		$transition_animation.play("transition_animation")
	if reverse:
		$transition_animation.play("transition_animation", -1,-1.0, true)


func _on_transition_animation_animation_finished(_anim_name):
	self.hide()


func _on_ui_transition(reverse):
	self.show()
	if not reverse:
		$transition_animation.play("transition_animation")
	if reverse:
		$transition_animation.play("transition_animation", -1,-1.0, true)
