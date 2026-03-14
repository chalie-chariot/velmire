extends Node2D

var speed: float = 90.0
var hp: float = 100.0
var max_hp: float = 100.0
var target: Vector2 = Vector2(960, 540)
var radius: float = 40.0
var _time: float = 0.0
var _pulse_time: float = 0.0
var _pulse_interval: float = 1.8
var _pulse_radius: float = 0.0
var _pulse_alpha: float = 0.0
var _pulsing: bool = false
var _tendrils: Array = []
var _tendril_count: int = 6
var _is_slowed: bool = false
var _hp_bar_alpha: float = 0.0
var _hp_bar_timer: float = 0.0
var _hp_bar_duration: float = 2.0
var _damage_bar_ratio: float = 1.0

func _ready() -> void:
	_generate_tendrils()

func _generate_tendrils() -> void:
	_tendrils.clear()
	for i in range(_tendril_count):
		var base_angle: float = (TAU / _tendril_count) * i
		var points: Array = []
		for j in range(4):
			var t: float = float(j) / 3.0
			var r: float = radius * 0.2 + radius * 0.8 * t
			var angle_offset: float = randf_range(-0.4, 0.4) * (1.0 - t)
			var angle: float = base_angle + angle_offset
			points.append(Vector2(cos(angle), sin(angle)) * r)
		_tendrils.append({
			points = points,
			width = randf_range(2.5, 4.5),
			phase = randf_range(0, TAU)
		})

func _process(delta: float) -> void:
	_time += delta
	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta

	_pulse_time += delta
	if _pulse_time >= _pulse_interval:
		_pulse_time = 0.0
		_pulse_radius = 0.0
		_pulse_alpha = 1.0
		_pulsing = true

	if _pulsing:
		_pulse_radius += radius * 3.5 * delta
		_pulse_alpha -= 1.8 * delta
		if _pulse_alpha <= 0:
			_pulsing = false

	if _hp_bar_timer > 0:
		_hp_bar_timer -= delta
		if _hp_bar_timer <= 0.5:
			_hp_bar_alpha = _hp_bar_timer / 0.5
	else:
		_hp_bar_alpha = 0.0

	queue_redraw()

func _draw() -> void:
	# 외곽 글로우
	draw_circle(Vector2.ZERO, radius * 1.1,
		Color(0.15, 0.0, 0.0, 0.6))

	# 줄기 (덩굴처럼 감싸는 곡선)
	for tendril in _tendrils:
		var pts: Array = tendril.points
		var w: float = tendril.width
		var phase: float = tendril.phase

		var pulse_glow: float = 0.0
		if _pulsing:
			var tendril_dist: float = pts[3].length()
			var diff: float = abs(_pulse_radius - tendril_dist * 0.5)
			if diff < radius * 0.4:
				pulse_glow = (1.0 - diff / (radius * 0.4)) * _pulse_alpha

		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var wave: float = sin(_time * 1.5 + phase + i) * 2.0
			var perp: Vector2 = (b - a).normalized().rotated(PI/2) * wave
			draw_line(a + perp, b + perp,
				Color(0.25, 0.0, 0.0, 0.9), w)

			if pulse_glow > 0:
				draw_line(a + perp, b + perp,
					Color(1.0, 0.1, 0.1, pulse_glow * 0.8), w * 0.6)

	# 핵 (중심부)
	draw_circle(Vector2.ZERO, radius * 0.28,
		Color(0.08, 0.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, radius * 0.18,
		Color(0.35, 0.0, 0.0, 1.0))

	if _pulsing:
		draw_circle(Vector2.ZERO, radius * 0.28 + _pulse_radius * 0.3,
			Color(0.9, 0.0, 0.0, _pulse_alpha * 0.5))

	draw_circle(Vector2.ZERO, radius * 0.08,
		Color(0.6, 0.0, 0.0, 0.9))

	# HP바
	if _hp_bar_alpha > 0:
		var angle: float = -rotation
		var bar_w: float = 50.0
		var bar_h: float = 6.0
		var bar_offset: Vector2 = Vector2(0, -radius - 20).rotated(angle)
		var bx: Vector2 = Vector2(cos(angle), sin(angle))
		var by: Vector2 = Vector2(-sin(angle), cos(angle))

		var tl = bar_offset + bx * (-bar_w/2) + by * (-bar_h/2)
		var tr = bar_offset + bx * (bar_w/2) + by * (-bar_h/2)
		var br = bar_offset + bx * (bar_w/2) + by * (bar_h/2)
		var bl = bar_offset + bx * (-bar_w/2) + by * (bar_h/2)

		draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]),
			Color(0.15, 0.0, 0.0, _hp_bar_alpha * 0.9))

		var tr_d = bar_offset + bx * (-bar_w/2 + bar_w * _damage_bar_ratio) + by * (-bar_h/2)
		var br_d = bar_offset + bx * (-bar_w/2 + bar_w * _damage_bar_ratio) + by * (bar_h/2)
		draw_colored_polygon(PackedVector2Array([tl, tr_d, br_d, bl]),
			Color(0.7, 0.7, 0.7, _hp_bar_alpha * 0.8))

		var hp_ratio: float = hp / max_hp
		var tr_h = bar_offset + bx * (-bar_w/2 + bar_w * hp_ratio) + by * (-bar_h/2)
		var br_h = bar_offset + bx * (-bar_w/2 + bar_w * hp_ratio) + by * (bar_h/2)
		draw_colored_polygon(PackedVector2Array([tl, tr_h, br_h, bl]),
			Color(1.0, 0.15, 0.15, _hp_bar_alpha))

func take_damage(amount: float) -> void:
	hp -= amount
	_hp_bar_alpha = 1.0
	_hp_bar_timer = _hp_bar_duration
	_spawn_damage_number(amount)
	if hp > 0:
		var tween: Tween = create_tween()
		tween.tween_interval(0.6)
		tween.tween_property(self, "_damage_bar_ratio", hp / max_hp, 0.4).set_ease(Tween.EASE_OUT)
	if hp <= 0:
		_spawn_death_effect()
		_drop_blood()
		remove_from_group("blood_entities")
		queue_free()

func _spawn_death_effect() -> void:
	var effect = Node2D.new()
	effect.set_script(preload("res://scripts/DeathEffect.gd"))
	effect.global_position = global_position
	get_parent().add_child(effect)

func _drop_blood() -> void:
	var drop_scene = preload("res://scenes/BloodDrop.tscn")
	var drop_value: float = max(1.0, max_hp / 60.0)
	var coffin_node = get_tree().get_first_node_in_group("coffin")
	if not coffin_node:
		return
	var drop_target: Vector2 = coffin_node.global_position + coffin_node.size / 2
	var drop = drop_scene.instantiate()
	get_parent().add_child(drop)
	drop.setup(global_position, drop_value, drop_target)

func _spawn_damage_number(amount: float) -> void:
	var label: Label = Label.new()
	label.text = str(int(amount))
	label.add_theme_font_size_override("font_size", 18)
	if amount > 30:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		label.add_theme_font_size_override("font_size", 24)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	label.global_position = global_position + Vector2(randf_range(-10, 10), -40)
	get_parent().add_child(label)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "global_position",
		label.global_position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(label.queue_free)

func is_slowed() -> bool:
	return _is_slowed

func apply_slow(factor: float, duration: float) -> void:
	_is_slowed = true
	speed *= factor
	await get_tree().create_timer(duration).timeout
	if is_inside_tree():
		speed /= factor
	_is_slowed = false
