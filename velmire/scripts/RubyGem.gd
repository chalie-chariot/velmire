extends Node2D

@onready var gem_rect: ColorRect = $GemRect
var _mat: ShaderMaterial
var _time: float = 0.0
var glow: float = 0.0  # 외부에서 0.0~1.0 설정


func _ready() -> void:
	_mat = gem_rect.material as ShaderMaterial


func _process(delta: float) -> void:
	_time += delta
	_mat.set_shader_parameter("time_val", _time)
	_mat.set_shader_parameter("glow_intensity", glow)
