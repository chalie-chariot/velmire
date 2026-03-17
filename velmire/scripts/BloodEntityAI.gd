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
var radius: float = 27.0
var _hp_bar_alpha: float = 0.0
var _hp_bar_timer: float = 0.0
var _hp_bar_duration: float = 2.0
var _damage_bar_ratio: float = 1.0

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_generate_points()

func _generate_points() -> void:
	var num: int = randi_range(6, 9)
	_points.clear()
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = radius + randf_range(-8.0, 8.0)
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

	# HP바 (회전 무시 고정)
	if _hp_bar_alpha > 0:
		var angle: float = -rotation
		var bar_w: float = 40.0
		var bar_h: float = 5.0
		var bar_offset: Vector2 = Vector2(0, -38).rotated(angle)
		var bx: Vector2 = Vector2(cos(angle), sin(angle))
		var by: Vector2 = Vector2(-sin(angle), cos(angle))

		var tl = bar_offset + bx * (-bar_w/2) + by * (-bar_h/2)
		var tr = bar_offset + bx * (bar_w/2) + by * (-bar_h/2)
		var br = bar_offset + bx * (bar_w/2) + by * (bar_h/2)
		var bl = bar_offset + bx * (-bar_w/2) + by * (bar_h/2)

		# 배경
		draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]),
			Color(0.15, 0.0, 0.0, _hp_bar_alpha * 0.9))

		# 데미지바 (회색 지연)
		var tr_d = bar_offset + bx * (-bar_w/2 + bar_w * _damage_bar_ratio) + by * (-bar_h/2)
		var br_d = bar_offset + bx * (-bar_w/2 + bar_w * _damage_bar_ratio) + by * (bar_h/2)
		draw_colored_polygon(PackedVector2Array([tl, tr_d, br_d, bl]),
			Color(0.7, 0.7, 0.7, _hp_bar_alpha * 0.8))

		# HP바 (빨강 즉시)
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
	# 데미지바 지연 감소
	if hp > 0:
		var tween: Tween = create_tween()
		tween.tween_interval(0.6)
		tween.tween_property(self, "_damage_bar_ratio", hp / max_hp, 0.4).set_ease(Tween.EASE_OUT)
	if hp <= 0:
		var main = get_tree().get_first_node_in_group("main")
		if main:
			main.trigger_hitstop(0.06)
			main.on_entity_killed()
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
	var coffin = get_tree().get_first_node_in_group("coffin")
	if not coffin:
		return
	var target: Vector2 = coffin.global_position + coffin.size / 2
	var dist: float = global_position.distance_to(target)
	var kill_in_coffin_range: bool = dist <= 250.0

	var drop_value: float = max(1.0, max_hp / 60.0)
	var drop = drop_scene.instantiate()
	get_parent().add_child(drop)
	drop.setup(global_position, drop_value, target, false, kill_in_coffin_range)

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
