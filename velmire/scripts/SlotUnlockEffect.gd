extends Node2D

var _time: float = 0.0
var _alpha: float = 1.0
var _speed: float = 6.0

# 3개 궤도 - 각각 다른 기울기
var _orbits: Array = [
	{"tilt": 0.0, "angle": 0.0, "color": Color(1.0, 0.15, 0.15)},
	{"tilt": PI / 3.0, "angle": TAU / 3.0, "color": Color(1.0, 0.15, 0.15)},
	{"tilt": -PI / 3.0, "angle": TAU * 2.0 / 3.0, "color": Color(1.0, 0.15, 0.15)},
]

var _radius_x: float = 55.0
var _radius_y: float = 22.0

func _process(delta: float) -> void:
	_time += delta
	# 감속
	_speed = max(_speed - 1.5 * delta, 0.3)
	# 페이드아웃
	_alpha -= 0.35 * delta
	if _alpha <= 0:
		queue_free()
		return
	# 각도 업데이트
	for orbit in _orbits:
		orbit.angle += _speed * delta
	queue_redraw()

func _draw() -> void:
	for orbit in _orbits:
		var tilt: float = orbit.tilt
		var angle: float = orbit.angle
		var color: Color = orbit.color

		# 타원 궤도 그리기 (기울어진)
		var orbit_pts: PackedVector2Array = []
		for i in range(65):
			var a: float = (TAU / 64.0) * i
			var x: float = cos(a) * _radius_x
			var y: float = sin(a) * _radius_y
			# tilt 회전 적용
			var rx: float = x * cos(tilt) - y * sin(tilt)
			var ry: float = x * sin(tilt) + y * cos(tilt)
			orbit_pts.append(Vector2(rx, ry))

		# 궤도 선 (반투명)
		for i in range(orbit_pts.size() - 1):
			draw_line(orbit_pts[i], orbit_pts[i + 1],
				Color(color.r, color.g, color.b, _alpha * 0.3), 1.2)

		# 전자 위치 계산
		var ex: float = cos(angle) * _radius_x
		var ey: float = sin(angle) * _radius_y
		var erx: float = ex * cos(tilt) - ey * sin(tilt)
		var ery: float = ex * sin(tilt) + ey * cos(tilt)
		var electron_pos: Vector2 = Vector2(erx, ery)

		# 혜성 꼬리 (뒤쪽 5개 포인트)
		for t in range(1, 6):
			var ta: float = angle - t * 0.25
			var tx: float = cos(ta) * _radius_x
			var ty: float = sin(ta) * _radius_y
			var trx: float = tx * cos(tilt) - ty * sin(tilt)
			var try_: float = tx * sin(tilt) + ty * cos(tilt)
			var tail_alpha: float = _alpha * (1.0 - t * 0.18)
			var tail_size: float = 4.0 - t * 0.6
			draw_circle(Vector2(trx, try_),
				max(tail_size, 0.5),
				Color(color.r, color.g, color.b, tail_alpha * 0.6))

		# 전자 본체
		draw_circle(electron_pos, 5.5,
			Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, _alpha))
		draw_circle(electron_pos, 3.5,
			Color(color.r, color.g, color.b, _alpha))
		draw_circle(electron_pos, 1.5,
			Color(1.0, 1.0, 1.0, _alpha * 0.9))
