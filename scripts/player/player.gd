extends CharacterBody2D

const JOHN_TEXTURE_PATH: String = "res://assets/sprites/player/john_v1.png"

@export var move_speed: float = 200.0

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _placeholder_sprite: Sprite2D = $Sprite2D

var _facing_direction: StringName = &"down"
var _has_john_frames: bool = false


func _ready() -> void:
	_bind_john_atlas()
	_has_john_frames = _has_complete_animation_set()
	_animated_sprite.visible = _has_john_frames
	_placeholder_sprite.visible = not _has_john_frames
	_update_animation(Vector2.ZERO)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_update_animation(direction)


func _update_animation(input_direction: Vector2) -> void:
	if not input_direction.is_zero_approx():
		# Empate entre componentes: prioridade vertical, sem animações diagonais.
		if absf(input_direction.x) > absf(input_direction.y):
			_facing_direction = &"right" if input_direction.x > 0.0 else &"left"
		else:
			_facing_direction = &"down" if input_direction.y > 0.0 else &"up"

	var state := "idle" if get_real_velocity().is_zero_approx() else "walk"
	var animation_name := StringName("%s_%s" % [state, _facing_direction])
	if _has_john_frames:
		_animated_sprite.play(animation_name)
	else:
		# Sem arte de produção: selecionar o estado sem tocar animações vazias.
		_animated_sprite.animation = animation_name


func _bind_john_atlas() -> void:
	var frames := _animated_sprite.sprite_frames
	if frames == null or not ResourceLoader.exists(JOHN_TEXTURE_PATH, "Texture2D"):
		return
	var atlas := load(JOHN_TEXTURE_PATH) as Texture2D
	if atlas == null or atlas.get_size() != Vector2(192, 384):
		push_warning("John V1 requer PNG técnico 192x384; placeholder preservado, sem redimensionamento.")
		return
	for animation_name in frames.get_animation_names():
		for frame_index in range(frames.get_frame_count(animation_name)):
			var texture := frames.get_frame_texture(animation_name, frame_index)
			if texture is AtlasTexture:
				texture.atlas = atlas


func _has_complete_animation_set() -> bool:
	var frames := _animated_sprite.sprite_frames
	if frames == null:
		return false
	for state in ["idle", "walk"]:
		for direction in ["down", "up", "left", "right"]:
			var animation_name := StringName("%s_%s" % [state, direction])
			if not frames.has_animation(animation_name) or frames.get_frame_count(animation_name) == 0:
				return false
			for frame_index in range(frames.get_frame_count(animation_name)):
				var texture := frames.get_frame_texture(animation_name, frame_index)
				if texture == null:
					return false
				if texture is AtlasTexture and texture.atlas == null:
					return false
				if texture is AtlasTexture and texture.atlas.get_size() != Vector2(192, 384):
					return false
	return true
