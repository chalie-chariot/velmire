extends Node2D

@onready var arc_rect: ColorRect = $ArcRect
var _mat: ShaderMaterial
var _ratio: float = 1.0
var _warning: float = 0.0
var _fade: float = 1.0

func _ready() -> void:
	# 링라이트 범위 반경 300px 기준 / ColorRect 크기 = 반경 * 2 = 600x600
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
	# 20% 이하면 빨강
	var w: float = 1.0 if ratio <= 0.2 else 0.0
	_mat.set_shader_parameter("warning", w)


func _on_fade_step(v: float) -> void:
	_mat.set_shader_parameter("fade", v)


func start_fadeout() -> void:
	var tw = create_tween()
	tw.tween_method(_on_fade_step, 1.0, 0.0, 0.6).set_ease(Tween.EASE_IN)
	var cb_free = func() -> void: queue_free()
	tw.tween_callback(cb_free)
