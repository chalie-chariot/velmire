extends Node2D

var value: float = 1.0
var _target: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _time: float = 0.0
var _size: float = 10.0
var _alpha: float = 1.0
var _phase: String = "burst"
var _burst_vel: Vector2 = Vector2.ZERO
var _curve_angle: float = 0.0  # 곡선 방향
var _trail: Array = []  # 잔상 위치 기록
var _is_stage4: bool = false  # 4단계 이상 여부
var _trail_max: int = 32
var _kill_in_coffin_range: bool = false
var _visual_only: bool = false  # 혈액 이미 지급됨(BloodEntityAI 등)

func setup(pos: Vector2, drop_value: float, coffin_center: Vector2, stage4: bool = false, kill_in_coffin_range: bool = false, visual_only: bool = false) -> void:
	global_position = pos
	value = drop_value
	_target = coffin_center
	_size = clamp(drop_value * 4.2, 7.0, 38.0)
	# 강하게 튕겨나감 - 관 반대 방향 기준으로 퍼짐
	var away_dir: Vector2 = (pos - coffin_center).normalized()
	var spread: float = randf_range(-0.6, 0.6)  # ±약 35도 퍼짐
	var burst_dir: Vector2 = away_dir.rotated(spread)
	_burst_vel = burst_dir * randf_range(500.0, 900.0)
	# 곡선 휘어질 방향 (시계/반시계 랜덤)
	_curve_angle = 1.0 if randf() > 0.5 else -1.0
	_is_stage4 = stage4
	_kill_in_coffin_range = kill_in_coffin_range
	_visual_only = visual_only

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
			if _is_stage4:
				_trail.append(global_position)
				if _trail.size() > _trail_max:
					_trail.pop_front()
			var dist: float = global_position.distance_to(_target)
			var dir: Vector2 = (_target - global_position).normalized()
			_speed += 3000.0 * delta
			global_position += dir * _speed * delta
			_size = clamp(dist / 45.0, 1.0, _size)

			if dist < 8.0:
				if _visual_only:
					queue_free()
					return
				var blood_mult: float = 1.0
				var hp = get_tree().get_first_node_in_group("heart_pulse")
				if hp and hp.has_method("get_max_blood_mult"):
					blood_mult = hp.get_max_blood_mult()
				var base_blood: float = value * blood_mult
				var final_blood: int = int(base_blood)

				if _kill_in_coffin_range:
					final_blood += 3
					final_blood += int(base_blood * 0.5)

				ResourceManager.add_blood(final_blood)
				ResourceManager.heal_coffin(value * 2.0 * blood_mult)

				var bonus: int = final_blood - int(base_blood)
				if bonus > 0:
					var main = get_tree().get_first_node_in_group("main")
					if main and main.has_method("_show_blood_bonus_popup"):
						main._show_blood_bonus_popup(bonus)

				queue_free()

	queue_redraw()

func _draw() -> void:
	if _is_stage4 and _trail.size() > 1:
		for i in range(_trail.size() - 1):
			var t: float = float(i) / _trail.size()
			var trail_pos: Vector2 = _trail[i] - global_position
			var trail_pos2: Vector2 = _trail[i + 1] - global_position
			var trail_alpha: float = t * 0.75
			var trail_width: float = _size * t * 2.4
			draw_line(trail_pos, trail_pos2,
				Color(0.9, 0.05, 0.05, trail_alpha), max(trail_width, 1.2))
	var pulse: float = sin(_time * 3.0) * 1.4
	var r: float = (_size + pulse) * 0.9
	draw_circle(Vector2.ZERO, r,
		Color(0.8, 0.0, 0.0, _alpha))
	draw_circle(Vector2.ZERO, r * 0.5,
		Color(1.0, 0.2, 0.2, _alpha * 0.8))
