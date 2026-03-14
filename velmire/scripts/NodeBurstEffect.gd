extends Node2D

var _color: Color = Color.WHITE
var _particles: Array = []
var _shockwave_radius: float = 0.0
var _shockwave_alpha: float = 1.0
var _flash_alpha: float = 1.0
var _time: float = 0.0

const _MAX_FALL_Y: float = 380.0  # 이 이상 아래로 가면 사라짐

func setup(color: Color) -> void:
	_color = color
	for i in range(16):
		var angle: float = (TAU / 16) * i + randf_range(-0.2, 0.2)
		var speed: float = randf_range(100.0, 280.0)
		var vel: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		# 위로 튀는 물방울 세기 보강
		if vel.y < 0:
			vel.y *= 1.5
		var size: float = randf_range(3.0, 7.0)
		_particles.append({
			pos = Vector2.ZERO,
			vel = vel,
			size = size,
			alpha = 1.0,
		})

func _process(delta: float) -> void:
	_time += delta

	# 충격파 링
	_shockwave_radius += 220.0 * delta
	_shockwave_alpha -= 2.5 * delta

	# 플래시
	_flash_alpha -= 4.0 * delta

	# 기존 파티클 로직 유지
	var all_dead: bool = true
	for p in _particles:
		p.vel.y += 500.0 * delta
		p.vel.x *= 0.97
		p.pos += p.vel * delta
		# 너무 아래로 가면 사라짐
		if p.pos.y > _MAX_FALL_Y:
			p.alpha = 0.0
		p.alpha -= 0.5 * delta
		# 떨어질수록(시간 지날수록) 크기 감소
		p.size -= 2.8 * delta
		if p.alpha > 0:
			all_dead = false

	if all_dead and _shockwave_alpha <= 0 and _flash_alpha <= 0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	# 플래시 (터지는 순간 번쩍)
	if _flash_alpha > 0:
		draw_circle(Vector2.ZERO, 65.0 * (1.0 - _flash_alpha * 0.4),
			Color(_color.r, _color.g, _color.b, max(_flash_alpha, 0.0)))

	# 충격파 링
	if _shockwave_alpha > 0:
		draw_arc(Vector2.ZERO, _shockwave_radius, 0, TAU, 64,
			Color(_color.r, _color.g, _color.b, max(_shockwave_alpha, 0.0)), 5.0)
		draw_arc(Vector2.ZERO, _shockwave_radius * 0.8, 0, TAU, 64,
			Color(_color.r, _color.g, _color.b, max(_shockwave_alpha * 0.6, 0.0)), 2.5)

	# 기존 파티클 (밑으로 갈수록 작아지는 스케일)
	for p in _particles:
		if p.alpha <= 0 or p.size <= 0:
			continue
		# 아래로 떨어질수록(p.pos.y 증가) 그려지는 크기 감소
		var fall_scale: float = 1.0 - clamp(p.pos.y / 250.0, 0.0, 0.55)
		var draw_size: float = max(p.size * fall_scale, 0.4)
		draw_circle(p.pos, draw_size,
			Color(_color.r, _color.g, _color.b, p.alpha))
