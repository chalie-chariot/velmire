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

func setup(pos: Vector2, drop_value: float, coffin_center: Vector2, stage4: bool = false, kill_in_coffin_range: bool = false) -> void:
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
					_show_blood_bonus_popup(bonus)

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

func _show_blood_bonus_popup(amount: int) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return
	var canvas_layer = main.get_node("CanvasLayer")

	var base_pos = Vector2(960, 895)

	var count = min(amount, 5)
	for i in range(count):
		var dot = Label.new()
		dot.text = "🩸"
		dot.add_theme_font_size_override("font_size", 14)
		dot.modulate = Color(1.0, 0.9, 0.1, 0.0)
		dot.z_index = 100
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.position = base_pos + Vector2(randf_range(-15.0, 15.0), 20)
		canvas_layer.add_child(dot)

		var dtw = create_tween()
		dtw.tween_interval(i * 0.06)
		dtw.set_parallel(true)
		dtw.tween_property(dot, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
		dtw.tween_property(dot, "position:y", dot.position.y - 50, 0.5).set_ease(Tween.EASE_OUT)
		dtw.tween_property(dot, "modulate:a", 0.0, 0.2).set_delay(0.35)
		var dcb = func(): dot.queue_free()
		dtw.tween_callback(dcb).set_delay(0.5)

	var bonus_label = Label.new()
	bonus_label.text = "+ " + str(amount)
	bonus_label.add_theme_font_size_override("font_size", 18)
	bonus_label.modulate = Color(1.0, 0.9, 0.1, 0.0)
	bonus_label.z_index = 100
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus_label.position = base_pos + Vector2(30, 0)
	canvas_layer.add_child(bonus_label)

	var ltw = create_tween()
	ltw.set_parallel(true)
	ltw.tween_property(bonus_label, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	ltw.tween_property(bonus_label, "position:y", base_pos.y - 40, 0.6).set_ease(Tween.EASE_OUT)
	ltw.tween_property(bonus_label, "modulate:a", 0.0, 0.25).set_delay(0.4)
	var lcb = func(): bonus_label.queue_free()
	ltw.tween_callback(lcb).set_delay(0.6)
