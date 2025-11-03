extends Node3D

@onready var sparks = $Sparks
@onready var smoke = $Smoke
@onready var fire = $Fire



func explode():
	sparks.emitting = true
	smoke.emitting = true
	fire.emitting = true



func _on_jet_explode():
	explode()
