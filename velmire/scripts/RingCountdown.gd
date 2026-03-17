extends Node2D

@onready var arc_rect: ColorRect = $ArcRect
var _mat: ShaderMaterial
var _ratio: float = 1.0
var _warning: float = 0.0
var _fade: float = 1.0

func _ready() -> void:
	var is_small: bool = get_meta("small", false)
	if is_small:
		arc_rect.size = Vector2(160, 160)
		arc_rect.pivot_offset = Vector2(80, 80)
		arc_rect.position = Vector2(-80, -80)
	else:
		arc_rect.size = Vector2(600, 600)
		arc_rect.pivot_offset = Vector2(300, 300)
		arc_rect.position = Vector2(-300, -300)
	_mat = arc_rect.material as ShaderMaterial
	_mat.set_shader_parameter("arc_ratio", 1.0)
	_mat.set_shader_parameter("warning", 0.0)
	_mat.set_shader_parameter("fade", 1.0)


func update_ratio(ratio: float) -> void:
	_ratio = ratio
	_mat.set_shader_parameter("arc_ratio", ratio)
	var no_warning: bool = get_meta("no_warning", false)
	var w: float = 0.0 if no_warning else (1.0 if ratio <= 0.2 else 0.0)
	_mat.set_shader_parameter("warning", w)


func _on_fade_step(v: float) -> void:
	_mat.set_shader_parameter("fade", v)


func start_fadeout() -> void:
	var tw = create_tween()
	tw.tween_method(_on_fade_step, 1.0, 0.0, 0.6).set_ease(Tween.EASE_IN)
	var cb_free = func() -> void: queue_free()
	tw.tween_callback(cb_free)
