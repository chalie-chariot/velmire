extends Node2D

var value: float = 1.0
var _target: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _time: float = 0.0
var _size: float = 6.0
var _alpha: float = 1.0
var _phase: String = "burst"
var _burst_vel: Vector2 = Vector2.ZERO
var _curve_angle: float = 0.0  # 곡선 방향

func setup(pos: Vector2, drop_value: float, coffin_center: Vector2) -> void:
	global_position = pos
	value = drop_value
	_target = coffin_center
	_size = clamp(drop_value * 2.0, 4.0, 16.0)
	# 강하게 튕겨나감 - 관 반대 방향 기준으로 퍼짐
	var away_dir: Vector2 = (pos - coffin_center).normalized()
	var spread: float = randf_range(-0.6, 0.6)  # ±약 35도 퍼짐
	var burst_dir: Vector2 = away_dir.rotated(spread)
	_burst_vel = burst_dir * randf_range(500.0, 900.0)
	# 곡선 휘어질 방향 (시계/반시계 랜덤)
	_curve_angle = 1.0 if randf() > 0.5 else -1.0

func _process(delta: float) -> void:
	_time += delta

	match _phase:
		"burst":
			_burst_vel *= 0.85
			global_position += _burst_vel * delta
			if _time > 0.4:
				_phase = "suck"
				_speed = 0.0

		"suck":
			var dist: float = global_position.distance_to(_target)
			var dir: Vector2 = (_target - global_position).normalized()
			_speed += 3000.0 * delta
			global_position += dir * _speed * delta
			_size = clamp(dist / 60.0, 0.5, _size)

			if dist < 8.0:
				ResourceManager.add_blood(value)
				queue_free()

	queue_redraw()

func _draw() -> void:
	var pulse: float = sin(_time * 3.0) * 0.8
	draw_circle(Vector2.ZERO, _size + pulse,
		Color(0.8, 0.0, 0.0, _alpha))
	draw_circle(Vector2.ZERO, (_size + pulse) * 0.5,
		Color(1.0, 0.2, 0.2, _alpha * 0.8))
