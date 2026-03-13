extends Node2D

var speed: float = 90.0
var hp: float = 100.0
var max_hp: float = 100.0
var damage: float = 10.0
var target: Vector2 = Vector2(960, 540)
var _rotation_speed: float = 0.0
var _points: PackedVector2Array = []
var _is_slowed: bool = false
var _base_radius: float = 35.0
var _hp_bar_alpha: float = 0.0
var _hp_bar_timer: float = 0.0
var _hp_bar_duration: float = 2.0
var _damage_bar_ratio: float = 1.0

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_generate_points()

func _generate_points() -> void:
	var num: int = randi_range(6, 9)
	_base_radius = randf_range(27.0, 42.0)
	_points.clear()
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = _base_radius + randf_range(-8.0, 8.0)
		_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _get_smooth_points() -> PackedVector2Array:
	var smooth: PackedVector2Array = []
	var count: int = _points.size()
	for i in range(count):
		var curr: Vector2 = _points[i]
		var next: Vector2 = _points[(i + 1) % count]
		var prev: Vector2 = _points[(i - 1 + count) % count]
		smooth.append(curr.lerp(prev, 0.16))
		smooth.append(curr.lerp((prev + next) / 2.0, 0.08))
		smooth.append(curr.lerp(next, 0.16))
	return smooth

func _process(delta: float) -> void:
	rotation += _rotation_speed * delta
	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta

	if _hp_bar_timer > 0:
		_hp_bar_timer -= delta
		if _hp_bar_timer <= 0.5:
			_hp_bar_alpha = _hp_bar_timer / 0.5
	else:
		_hp_bar_alpha = 0.0

	queue_redraw()

func _draw() -> void:
	if _points.size() == 0:
		return
	var smooth: PackedVector2Array = _get_smooth_points()
	draw_colored_polygon(smooth, Color(0.35, 0.0, 0.0, 1.0))
	for i in range(smooth.size()):
		var a: Vector2 = smooth[i]
		var b: Vector2 = smooth[(i + 1) % smooth.size()]
		draw_line(a, b, Color(0.6, 0.05, 0.05, 1.0), 1.5)

	if _hp_bar_alpha > 0:
		var angle: float = -rotation
		var bar_w: float = 40.0
		var bar_h: float = 5.0
		var bar_offset: Vector2 = Vector2(0, -38).rotated(angle)
		var bar_x: Vector2 = Vector2(cos(angle), sin(angle))
		var bar_y: Vector2 = Vector2(-sin(angle), cos(angle))

		var tl: Vector2 = bar_offset + bar_x * (-bar_w / 2) + bar_y * (-bar_h / 2)
		var tr: Vector2 = bar_offset + bar_x * (bar_w / 2) + bar_y * (-bar_h / 2)
		var br: Vector2 = bar_offset + bar_x * (bar_w / 2) + bar_y * (bar_h / 2)
		var bl: Vector2 = bar_offset + bar_x * (-bar_w / 2) + bar_y * (bar_h / 2)

		draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]),
			Color(0.15, 0.0, 0.0, _hp_bar_alpha * 0.9))

		var tr_d: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * _damage_bar_ratio) + bar_y * (-bar_h / 2)
		var br_d: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * _damage_bar_ratio) + bar_y * (bar_h / 2)
		draw_colored_polygon(PackedVector2Array([tl, tr_d, br_d, bl]),
			Color(0.7, 0.7, 0.7, _hp_bar_alpha * 0.8))

		var hp_ratio: float = hp / max_hp
		var tr_h: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * hp_ratio) + bar_y * (-bar_h / 2)
		var br_h: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * hp_ratio) + bar_y * (bar_h / 2)
		draw_colored_polygon(PackedVector2Array([tl, tr_h, br_h, bl]),
			Color(1.0, 0.15, 0.15, _hp_bar_alpha))

func take_damage(amount: float) -> void:
	hp -= amount
	_hp_bar_alpha = 1.0
	_hp_bar_timer = _hp_bar_duration
	_spawn_damage_number(amount)
	if hp <= 0:
		remove_from_group("blood_entities")
		queue_free()
		return
	var tween: Tween = create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(self, "_damage_bar_ratio",
		hp / max_hp, 0.3).set_ease(Tween.EASE_OUT)

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
