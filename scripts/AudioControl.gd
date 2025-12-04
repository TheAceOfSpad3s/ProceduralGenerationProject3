extends HSlider

@export var audio_bus_name: String
var audio_bus_id

func _ready():
	# 1. Get the Bus ID as usual
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)

	# 2. THE FIX: Get the current actual volume from the AudioServer
	var current_db = AudioServer.get_bus_volume_db(audio_bus_id)
	
	# 3. Convert that dB value back to a linear value (0.0 to 1.0) 
	# and set the slider's position ('value') to match.
	value = db_to_linear(current_db)


func _on_value_changed(currentvalue):
	var db = linear_to_db(currentvalue)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
