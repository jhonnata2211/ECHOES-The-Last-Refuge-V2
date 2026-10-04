extends Control

const GAMEPLAY_SCENE: String = "res://scenes/main/Main.tscn"

var _starting: bool = false

@onready var _start_button: Button = $Margin/Center/Rows/StartButton
@onready var _sound: SoundExperienceController = get_tree().root.get_node("SoundExperience")


func _ready() -> void:
	$Margin.hide()
	_start_button.disabled = true
	_sound.menu_ready.connect(_on_menu_ready)
	_sound.gameplay_transition_ready.connect(_on_gameplay_transition_ready)
	_sound.begin_menu()


func _on_menu_ready() -> void:
	$Margin.show()
	_start_button.disabled = false
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	if _starting or _start_button.disabled:
		return
	_starting = true
	_start_button.disabled = true
	if not _sound.request_gameplay_transition():
		_starting = false
		_start_button.disabled = false


func _on_gameplay_transition_ready() -> void:
	if not _starting:
		return
	var result: Error = get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	if result != OK:
		_starting = false
		_sound.begin_menu()
		push_error("Não foi possível abrir o gameplay de ECHOES: %s" % error_string(result))
