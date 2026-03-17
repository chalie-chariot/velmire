extends Node2D

## 루비/칩 흡수 연출용 아이콘 - 스폰 위치에서 UI로 tween 이동 후 ResourceManager 반영

var _target: Vector2 = Vector2.ZERO
var _is_chip: bool = false
var _size: float = 14.0
var _tween: Tween


func setup(target_pos: Vector2, is_chip: bool) -> void:
	_target = target_pos
	_is_chip = is_chip


func _ready() -> void:
	_start_tween()


func _start_tween() -> void:
	var duration: float = 0.5
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "global_position", _target, duration)
	_tween.tween_callback(_on_tween_done)


func _on_tween_done() -> void:
	if _is_chip:
		ResourceManager.add_chip(1)
	else:
		ResourceManager.add_ruby(1)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _is_chip:
		# 칩: 파란 다이아몬드
		var pts: PackedVector2Array = [
			Vector2(0, -_size),
			Vector2(_size, 0),
			Vector2(0, _size),
			Vector2(-_size, 0),
		]
		draw_colored_polygon(pts, Color(0.4, 0.5, 1.0, 0.9))
	else:
		# 루비: 빨간 원
		draw_circle(Vector2.ZERO, _size, Color(0.9, 0.15, 0.15, 0.95))
		draw_circle(Vector2.ZERO, _size * 0.5, Color(1.0, 0.35, 0.35, 0.8))
