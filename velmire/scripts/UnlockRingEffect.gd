extends Node2D

var _time: float = 0.0
var _rings: Array = []

func _ready() -> void:
	for i in range(3):
		_rings.append({
			"angle": (TAU / 3.0) * i,
			"speed": 8.0,
			"radius": 50.0,
			"alpha": 1.0,
			"trail": []
		})

func _process(delta: float) -> void:
	_time += delta
	var all_done: bool = true

	for ring in _rings:
		ring.speed = max(ring.speed - 4.0 * delta, 0.5)
		ring.angle += ring.speed * delta
		ring.alpha -= 0.4 * delta

		var pos: Vector2 = Vector2(
			cos(ring.angle) * ring.radius,
			sin(ring.angle) * ring.radius * 0.4
		)

		ring.trail.append(pos)
		if ring.trail.size() > 12:
			ring.trail.pop_front()

		if ring.alpha > 0:
			all_done = false

	if all_done:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for ring in _rings:
		if ring.alpha <= 0:
			continue

		var trail_size: int = ring.trail.size()
		for i in range(trail_size - 1):
			var t: float = float(i) / trail_size
			var tail_alpha: float = t * ring.alpha * 0.6
			var tail_width: float = t * 3.0
			draw_line(
				ring.trail[i],
				ring.trail[i + 1],
				Color(1.0, 0.1, 0.1, tail_alpha),
				max(tail_width, 0.5)
			)

		if ring.trail.size() > 0:
			var head: Vector2 = ring.trail[-1]
			draw_circle(head, 5.0,
				Color(1.0, 0.3, 0.3, ring.alpha))
			draw_circle(head, 3.0,
				Color(1.0, 0.8, 0.8, ring.alpha * 0.9))
