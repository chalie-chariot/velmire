extends Node2D

var _time: float = 0.0
var _particles: Array = []
var _death_color: Color = Color(0.85, 0.1, 0.1, 1.0)

func _ready() -> void:
	_death_color = get_meta("death_color", Color(0.85, 0.1, 0.1, 1.0))
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
			Color(_death_color.r, _death_color.g, _death_color.b, flash_a * 0.7))

	for p in _particles:
		if p.alpha <= 0 or p.size <= 0:
			continue
		draw_circle(p.pos, max(p.size, 0.5),
			Color(_death_color.r, _death_color.g, _death_color.b, p.alpha))
		var trail: Vector2 = p.pos - p.vel.normalized() * p.size * 2.0
		draw_line(p.pos, trail,
			Color(_death_color.r, _death_color.g, _death_color.b, p.alpha * 0.5), max(p.size * 0.4, 0.5))

	if _time < 0.6:
		var ring_a: float = (0.6 - _time) / 0.6
		var ring_r: float = _time * 500.0
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 64,
			Color(_death_color.r, _death_color.g, _death_color.b, ring_a * 0.8), 2.5)
		draw_arc(Vector2.ZERO, ring_r * 0.7, 0, TAU, 64,
			Color(_death_color.r, _death_color.g, _death_color.b, ring_a * 0.4), 1.5)
