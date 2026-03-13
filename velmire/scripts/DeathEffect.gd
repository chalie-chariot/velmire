extends Node2D

var _time: float = 0.0
var _particles: Array = []

func _ready() -> void:
	for i in range(30):
		var angle: float = (TAU / 30.0) * i + randf_range(-0.2, 0.2)
		var speed: float = randf_range(150.0, 450.0)
		var size: float = randf_range(6.0, 18.0)
		_particles.append({
			pos = Vector2.ZERO,
			vel = Vector2(cos(angle), sin(angle)) * speed,
			size = size,
			alpha = 1.0
		})

func _process(delta: float) -> void:
	_time += delta
	var all_dead: bool = true
	for p in _particles:
		p.vel *= 0.93
		p.pos += p.vel * delta
		p.alpha -= 0.9 * delta
		p.size -= 2.0 * delta
		if p.alpha > 0:
			all_dead = false
	if all_dead:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if _time < 0.2:
		var flash_a: float = (0.2 - _time) / 0.2
		draw_circle(Vector2.ZERO, 120.0 * flash_a,
			Color(1.0, 0.3, 0.3, flash_a * 0.7))

	for p in _particles:
		if p.alpha <= 0 or p.size <= 0:
			continue
		draw_circle(p.pos, max(p.size, 0.5),
			Color(0.9, 0.05, 0.05, p.alpha))
		var trail: Vector2 = p.pos - p.vel.normalized() * p.size * 2.0
		draw_line(p.pos, trail,
			Color(1.0, 0.3, 0.3, p.alpha * 0.5), max(p.size * 0.4, 0.5))

	if _time < 0.6:
		var ring_a: float = (0.6 - _time) / 0.6
		var ring_r: float = _time * 500.0
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 64,
			Color(1.0, 0.2, 0.2, ring_a * 0.8), 2.5)
		draw_arc(Vector2.ZERO, ring_r * 0.7, 0, TAU, 64,
			Color(1.0, 0.4, 0.4, ring_a * 0.4), 1.5)
