extends Node2D

# 혈체 파괴 시 터지는 파편 이펙트
var _particles: Array = []  # { pos, vel, size, alpha }

func _ready() -> void:
	# 바깥으로 터져나가는 혈액 파편 12개
	for i in range(12):
		var angle: float = randf_range(0, TAU)
		var spd: float = randf_range(120.0, 280.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"size": randf_range(4.0, 10.0),
			"alpha": randf_range(0.8, 1.0)
		})

func _process(delta: float) -> void:
	var all_dead: bool = true
	for p in _particles:
		p.pos += p.vel * delta
		p.vel *= 0.88
		p.alpha -= 1.8 * delta
		if p.alpha > 0:
			all_dead = false
	if all_dead:
		queue_free()
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		if p.alpha <= 0:
			continue
		var c: Color = Color(0.9, 0.1, 0.1, p.alpha)
		draw_circle(p.pos, p.size, c)
		draw_circle(p.pos, p.size * 0.5, Color(1.0, 0.3, 0.3, p.alpha * 0.7))
