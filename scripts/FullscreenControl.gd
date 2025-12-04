extends CheckButton

func _ready():
	# Check the current window mode from the DisplayServer
	var current_mode = DisplayServer.window_get_mode()
	
	# If the current mode is FULLSCREEN (or EXCLUSIVE_FULLSCREEN), set the button to "on"
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		button_pressed = true
	else:
		button_pressed = false

func _on_toggled(toggled_on):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
