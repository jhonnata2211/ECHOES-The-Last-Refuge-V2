extends CharacterBody2D

const JOHN_TEXTURE_PATH: String = "res://assets/sprites/player/john_v1.png"

@export var move_speed: float = 200.0
@export var sprint_speed: float = 320.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_consumption_rate: float = 20.0
@export var stamina_recovery_rate: float = 15.0
@export var stamina_recovery_delay: float = 1.0
@export_range(0.0, 1.0) var exhaustion_recovery_ratio: float = 0.30

signal stamina_changed(current: float, maximum: float)

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _placeholder_sprite: Sprite2D = $Sprite2D

var _facing_direction: StringName = &"down"
var _has_john_frames: bool = false
var _touch_direction := Vector2.ZERO
var _touch_sprint_pressed: bool = false

var _stamina: float
var _stamina_exhausted: bool = false
var _stamina_recovery_timer: float = 0.0


func _ready() -> void:
        _stamina = max_stamina
        _bind_john_atlas()
        _has_john_frames = _has_complete_animation_set()
        _animated_sprite.visible = _has_john_frames
        _placeholder_sprite.visible = not _has_john_frames
        _update_animation(Vector2.ZERO)


func _physics_process(delta: float) -> void:
        var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        if direction == Vector2.ZERO:
                direction = _touch_direction

        var sprint_requested := Input.is_action_pressed("sprint") or _touch_sprint_pressed
        var sprint_authorized := _can_sprint(sprint_requested, direction)

        var current_speed := sprint_speed if sprint_authorized else move_speed
        velocity = direction * current_speed

        _update_stamina(delta, sprint_authorized)

        move_and_slide()
        _update_animation(direction)


func set_touch_direction(direction: Vector2) -> void:
        _touch_direction = direction.limit_length(1.0)


func set_touch_sprint_pressed(pressed: bool) -> void:
        _touch_sprint_pressed = pressed


func get_stamina() -> float:
        return _stamina


func get_max_stamina() -> float:
        return max_stamina


func _can_sprint(sprint_requested: bool, direction: Vector2) -> bool:
        if not sprint_requested:
                return false

        if direction.is_zero_approx():
                return false

        if _stamina_exhausted:
                return false

        return _stamina > 0.0


func _update_stamina(delta: float, sprint_authorized: bool) -> void:
        var previous_stamina := _stamina

        if sprint_authorized:
                _stamina -= stamina_consumption_rate * delta
                _stamina = clampf(_stamina, 0.0, max_stamina)
                _stamina_recovery_timer = 0.0

                if is_zero_approx(_stamina):
                        _stamina_exhausted = true
        else:
                _stamina_recovery_timer += delta

                if _stamina_recovery_timer >= stamina_recovery_delay:
                        _stamina += stamina_recovery_rate * delta
                        _stamina = clampf(_stamina, 0.0, max_stamina)

                var recovery_threshold := max_stamina * exhaustion_recovery_ratio
                if _stamina_exhausted and _stamina >= recovery_threshold:
                        _stamina_exhausted = false

        if not is_equal_approx(previous_stamina, _stamina):
                stamina_changed.emit(_stamina, max_stamina)


func _update_animation(input_direction: Vector2) -> void:
        if not input_direction.is_zero_approx():
                # Empate entre componentes: prioridade vertical, sem animações diagonais.
                if absf(input_direction.x) > absf(input_direction.y):
                        _facing_direction = &"right" if input_direction.x > 0.0 else &"left"
                else:
                        _facing_direction = &"down" if input_direction.y > 0.0 else &"up"

        var state := "idle" if input_direction.is_zero_approx() or get_real_velocity().is_zero_approx() else "walk"
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