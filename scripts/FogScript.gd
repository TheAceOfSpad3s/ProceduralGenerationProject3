extends FogVolume

var IsShowing = false
var FogSpeed: float = 0.0
@onready var environment = $"../../WorldEnvironment"
# Called when the node enters the scene tree for the first time.
func _ready():
	if not IsShowing:
		self.hide()

func _physics_process(delta):
	if IsShowing:
		position.z += FogSpeed * delta


func _on_chunk_manager_fog_activation(is_showing, fog_speed, fog_offset):
	position.z = fog_offset

	FogSpeed = fog_speed
	if is_showing:
		self.show()
		IsShowing = true
	elif not is_showing:
		self.hide()
		IsShowing = false
	else:
		print("error")




