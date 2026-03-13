extends Node2D
var _radius: float = 10.0
var _alpha: float = 0.8

func _process(delta: float) -> void:
	_radius += 180.0 * delta
	_alpha -= 2.5 * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, _alpha), 3.0)
