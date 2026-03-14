extends Node2D

var _color: Color = Color.WHITE
var _particles: Array = []

func setup(color: Color) -> void:
	_color = color
	for i in range(16):
		var angle: float = (TAU / 16) * i + randf_range(-0.2, 0.2)
		var speed: float = randf_range(80.0, 220.0)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		# x 배율 제거 (원래대로)
		var size: float = randf_range(2.0, 5.0)
		_particles.append({
			pos = Vector2.ZERO,
			vel = vel,
			size = size,
			alpha = 1.0,
		})

func _process(delta: float) -> void:
	var all_dead: bool = true
	for p in _particles:
		# 중력 (위로 갔다가 아래로 떨어짐)
		p.vel.y += 500.0 * delta
		p.vel.x *= 0.97
		p.pos += p.vel * delta
		# 페이드아웃 느리게
		p.alpha -= 0.8 * delta
		p.size -= 2.0 * delta
		if p.alpha > 0:
			all_dead = false
	if all_dead:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		if p.alpha <= 0 or p.size <= 0:
			continue
		# 단색만
		draw_circle(p.pos, max(p.size, 0.5),
			Color(_color.r, _color.g, _color.b, p.alpha))
