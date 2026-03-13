extends Node2D

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _alpha: float = 0.9

func _process(delta: float) -> void:
	_alpha -= delta * 0.5
	if _alpha <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_line(_from, _to,
		Color(_color.r, _color.g, _color.b, _alpha), 2.0)
	draw_circle(_to, 4.0,
		Color(1.0, 1.0, 1.0, _alpha * 0.6))
