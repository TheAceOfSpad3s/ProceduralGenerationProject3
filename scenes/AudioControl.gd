extends HSlider

@export var audio_bus_name: String
var audio_bus_id
# Called when the node enters the scene tree for the first time.
func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)





func _on_value_changed(currentvalue):
	var db = linear_to_db(currentvalue)
	AudioServer.set_bus_volume_db(audio_bus_id,db)
