extends Node2D

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _from_color: Color = Color.WHITE
var _to_color: Color = Color.WHITE
var _time: float = 0.0
var _phase: String = "gather"
var _particles: Array = []
var _burst_particles: Array = []

func setup(from: Vector2, to: Vector2, fc: Color, tc: Color) -> void:
	_from = from
	_to = to
	_from_color = fc
	_to_color = tc
	global_position = Vector2.ZERO

	# 수렴 입자 (양쪽에서 중앙으로) - from 쪽 6개는 from 색상만, to 쪽 6개는 to 색상만
	var mid: Vector2 = (from + to) / 2.0
	for i in range(12):
		var t: float = float(i) / 12.0
		var p_color: Color = fc if i < 6 else tc
		var start_pos: Vector2 = from.lerp(to, t)
		_particles.append({
			pos = start_pos,
			target = mid,
			speed = randf_range(250.0, 450.0),
			size = randf_range(3.0, 8.0),
			alpha = 1.0,
			color = p_color
		})

func _spawn_burst() -> void:
	var mid: Vector2 = (_from + _to) / 2.0

	# from 색상 파티클 20개 (팍 터지는 범위 축소)
	for i in range(20):
		var angle: float = randf_range(0, TAU)
		var speed: float = randf_range(120.0, 280.0)
		_burst_particles.append({
			pos = mid,
			vel = Vector2(cos(angle), sin(angle)) * speed,
			size = randf_range(3.0, 9.0),
			alpha = 1.0,
			color = _from_color,
			gravity = randf_range(40.0, 120.0)
		})

	# to 색상 파티클 20개 (팍 터지는 범위 축소)
	for i in range(20):
		var angle: float = randf_range(0, TAU)
		var speed: float = randf_range(120.0, 280.0)
		_burst_particles.append({
			pos = mid,
			vel = Vector2(cos(angle), sin(angle)) * speed,
			size = randf_range(3.0, 9.0),
			alpha = 1.0,
			color = _to_color,
			gravity = randf_range(40.0, 120.0)
		})

func _process(delta: float) -> void:
	_time += delta

	match _phase:
		"gather":
			var mid: Vector2 = (_from + _to) / 2.0
			var all_arrived: bool = true
			for p in _particles:
				var dist: float = p.pos.distance_to(mid)
				if dist > 8.0:
					var dir: Vector2 = (mid - p.pos).normalized()
					p.pos += dir * p.speed * delta
					all_arrived = false
				p.alpha = min(p.alpha, dist / 50.0 + 0.3)
			if all_arrived or _time > 0.35:
				_phase = "explode"
				_time = 0.0
				_spawn_burst()

		"explode":
			for p in _burst_particles:
				p.vel.y += p.gravity * delta
				p.vel *= 0.97  # 덜 감쇠 → 떨어지는 모션 더 오래 유지
				p.pos += p.vel * delta
				p.alpha -= 0.45 * delta  # 더 천천히 페이드 (떨어지는 시간 추가)
				p.size -= 0.9 * delta

			var all_dead: bool = true
			for p in _burst_particles:
				if p.alpha > 0:
					all_dead = false
			if all_dead or _time > 4.0:  # 밑으로 떨어지는 애니메이션 시간 증가
				queue_free()

	queue_redraw()

func _draw() -> void:
	var mid: Vector2 = (_from + _to) / 2.0

	match _phase:
		"gather":
			# 연결선 (from→to 그라데이션, 시너지 컬러만)
			var line_alpha: float = (_time / 0.35) * 0.8
			draw_line(_from, mid,
				Color(_from_color.r, _from_color.g, _from_color.b, line_alpha * 0.8), 6.0)
			draw_line(mid, _to,
				Color(_to_color.r, _to_color.g, _to_color.b, line_alpha * 0.8), 6.0)
			draw_line(_from, mid,
				Color(_from_color.r, _from_color.g, _from_color.b, line_alpha), 2.0)
			draw_line(mid, _to,
				Color(_to_color.r, _to_color.g, _to_color.b, line_alpha), 2.0)

			# 수렴 입자
			for p in _particles:
				if p.alpha > 0:
					draw_circle(p.pos, max(p.size, 0.5),
						Color(p.color.r, p.color.g, p.color.b, p.alpha))
					# 글로우
					draw_circle(p.pos, max(p.size * 1.8, 1.0),
						Color(p.color.r, p.color.g, p.color.b, p.alpha * 0.3))

		"explode":
			# 터질 때 글로우 효과 (중앙에서 퍼져나가는 부드러운 빛)
			var glow_a: float = max(1.0 - _time * 3.0, 0.0)
			if glow_a > 0:
				var glow_radius: float = 40.0 + _time * 200.0
				# 외곽부터 그리기 (가장 연한 레이어 먼저)
				for i in range(8):
					var t: float = float(i + 1) / 8.0
					var r: float = glow_radius * t
					var a: float = glow_a * (0.06 * (1.0 - t * 0.7))
					draw_circle(mid, r,
						Color(_from_color.r, _from_color.g, _from_color.b, a))
				draw_circle(mid, 35.0,
					Color(_from_color.r, _from_color.g, _from_color.b, glow_a * 0.25))
				draw_circle(mid, 18.0,
					Color(_from_color.r, _from_color.g, _from_color.b, glow_a * 0.5))
				draw_circle(mid, 8.0,
					Color(_from_color.r, _from_color.g, _from_color.b, glow_a * 0.8))

			# 링 버스트 (주체 노드=from 색상만)
			var ring_r: float = _time * 250.0
			var ring_a: float = max(1.0 - _time * 4.0, 0.0)
			if ring_a > 0:
				draw_arc(mid, ring_r, 0, TAU, 64,
					Color(_from_color.r, _from_color.g, _from_color.b, ring_a * 0.9), 5.0)
				draw_arc(mid, ring_r * 0.6, 0, TAU, 64,
					Color(_from_color.r, _from_color.g, _from_color.b, ring_a * 0.6), 3.0)

			var ring_r2: float = _time * 400.0
			var ring_a2: float = max(1.0 - _time * 2.5, 0.0)
			if ring_a2 > 0:
				draw_arc(mid, ring_r2, 0, TAU, 64,
					Color(_from_color.r, _from_color.g, _from_color.b, ring_a2 * 0.9), 4.0)
				draw_arc(mid, ring_r2 * 0.7, 0, TAU, 64,
					Color(_from_color.r, _from_color.g, _from_color.b, ring_a2 * 0.4), 2.0)

			# 파티클 (시너지 컬러만)
			for p in _burst_particles:
				if p.alpha <= 0 or p.size <= 0:
					continue
				# 글로우
				draw_circle(p.pos, max(p.size * 1.6, 0.5),
					Color(p.color.r, p.color.g, p.color.b, p.alpha * 0.3))
				# 본체
				draw_circle(p.pos, max(p.size, 0.5),
					Color(p.color.r, p.color.g, p.color.b, p.alpha))
