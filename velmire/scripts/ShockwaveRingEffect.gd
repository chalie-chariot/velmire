extends Node2D
var _radius: float = 20.0
var _alpha: float = 0.9
var _delay: float = 0.0
var _started: bool = false
var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	if _time < _delay:
		return
	if not _started:
		_started = true
	_radius += 320.0 * delta
	_alpha -= 2.2 * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if not _started:
		return
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 64, Color(1.0, 0.15, 0.15, _alpha), 4.0)
	draw_arc(Vector2.ZERO, _radius * 0.85, 0, TAU, 64, Color(1.0, 0.5, 0.5, _alpha * 0.4), 2.0)
