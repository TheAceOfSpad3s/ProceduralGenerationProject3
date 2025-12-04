extends Control


const DEFAULT_FONT = preload("res://Game Logo/airstrikebold3d.ttf")
const HOVER_FONT = preload("res://Game Logo/airstrike.ttf")

var pressed = false
@onready var options_menu = $OptionsMenu
@onready var buttons = $Buttons
@onready var title_logo = $"Title Logo"

signal Transition(reverse: bool)
func _ready():
	Transition.emit(true)
	await get_tree().create_timer(0.4).timeout
	$"Title Logo/AnimationPlayer".play("Title_Slam")
	buttons.visible = true
	title_logo.visible = true
	options_menu.visible = false

func _on_play_pressed():
	$Buttons/Play/jetpointer.visible = false
	$Buttons/Play/Pressed.visible = true
	$Buttons/Play/RichTextLabel.text = "[center][color=#000000]P[/color][color=#000000]L[/color][color=#000000]A[/color][color=#000000]Y[/color][/center]"
	$Buttons/Play/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)
	pressed = true
	Transition.emit(false)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/intro.tscn")


func _on_options_pressed():
	print("options")
	buttons.visible = false
	title_logo.visible = false
	options_menu.visible = true


func _on_quit_pressed():
	$Buttons/Quit/jetpointer.visible = false
	$Buttons/Quit/Pressed.visible = true
	$Buttons/Quit/RichTextLabel.text = "[center][color=#000000]Q[/color][color=#000000]U[/color][color=#000000]I[/color][color=#000000]T[/color][/center]"
	$Buttons/Quit/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)
	pressed = true
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func _on_quit_mouse_entered():
	if not pressed:
		$Buttons/Quit/jetpointer.visible = true
		$Buttons/Quit/RichTextLabel.text = "[center][color=#FF8800]Q[/color][color=#FFAA22]U[/color][color=#FFCC44]I[/color][color=#FFEE66]T[/color][/center]"
		$Buttons/Quit/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)
func _on_quit_mouse_exited():
	if not pressed:
		$Buttons/Quit/jetpointer.visible = false
		$Buttons/Quit/RichTextLabel.text = "[center][color=#0077FF]Q[/color][color=#2299FF]U[/color][color=#44BBFF]I[/color][color=#66DDFF]T[/color][/center]"
		$Buttons/Quit/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)


func _on_play_mouse_entered():
	if not pressed:
		$Buttons/Play/jetpointer.visible = true
		$Buttons/Play/RichTextLabel.text = "[center][color=#FF8800]P[/color][color=#FFAA22]L[/color][color=#FFCC44]A[/color][color=#FFEE66]Y[/color][/center]"
		$Buttons/Play/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)


func _on_play_mouse_exited():
	if not pressed:
		$Buttons/Play/jetpointer.visible = false
		$Buttons/Play/RichTextLabel.text = "[center][color=#0077FF]P[/color][color=#2299FF]L[/color][color=#44BBFF]A[/color][color=#66DDFF]Y[/color][/center]"
		$Buttons/Play/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)


func _on_options_mouse_entered():
	$Buttons/Options/jetpointer.visible = true
	$Buttons/Options/RichTextLabel.text = "[center][color=#FF8800]O[/color][color=#FFAA22]P[/color][color=#FFCC44]T[/color][color=#FFEE66]I[/color][color=#FFF077]O[/color][color=#FFF288]N[/color][color=#FFF499]S[/color][/center]"
	$Buttons/Options/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)


func _on_options_mouse_exited():
	$Buttons/Options/jetpointer.visible = false
	$Buttons/Options/RichTextLabel.text = "[center][color=#0077FF]O[/color][color=#1188FF]P[/color][color=#2299FF]T[/color][color=#33AADD]I[/color][color=#44BBFF]O[/color][color=#55CCFF]N[/color][color=#66DDFF]S[/color][/center]"
	$Buttons/Options/RichTextLabel.add_theme_font_override("normal_font",HOVER_FONT)


func _on_back_pressed():
	buttons.visible = true
	title_logo.visible = true
	options_menu.visible = false


func _on_back_mouse_entered():
	$OptionsMenu/Back/RichTextLabel.text = "[color=#000000]X[/color]"


func _on_back_mouse_exited():
	$OptionsMenu/Back/RichTextLabel.text = "X"


