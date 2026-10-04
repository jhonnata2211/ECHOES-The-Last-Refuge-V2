extends Control

const GAMEPLAY_SCENE: String = "res://scenes/main/Main.tscn"

var _starting: bool = false

@onready var _start_button: Button = $Margin/Center/Rows/StartButton


func _ready() -> void:
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	_start_button.disabled = true
	var result: Error = get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	if result != OK:
		_starting = false
		_start_button.disabled = false
		push_error("Não foi possível abrir o gameplay de ECHOES: %s" % error_string(result))
