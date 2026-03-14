extends Node2D

var radius: float = 40.0
var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 60.0
var target: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _pulse_time: float = 0.0
var _pulse_interval: float = 1.8
var _pulse_radius: float = 0.0
var _pulse_alpha: float = 0.0
var _pulsing: bool = false
var _tendrils: Array = []
var _tendril_count: int = 7
var _silhouette_pts: PackedVector2Array = []  # 다각형 실루엣
var _nucleus_pts: PackedVector2Array = []    # 유기체 핵 (불규칙 형태)
var _is_slowed: bool = false
var _hp_bar_alpha: float = 0.0
var _hp_bar_timer: float = 0.0
var _damage_bar_ratio: float = 1.0

func _ready() -> void:
	add_to_group("blood_entities")
	_generate_silhouette()
	_generate_nucleus()
	_generate_tendrils()

func _generate_silhouette() -> void:
	_silhouette_pts.clear()
	var num: int = randi_range(10, 16)
	for i in range(num):
		var angle: float = (TAU / num) * i + randf_range(-0.15, 0.15)
		var r: float = radius * randf_range(0.7, 1.1)
		_silhouette_pts.append(Vector2(cos(angle) * r, sin(angle) * r))

func _generate_nucleus() -> void:
	_nucleus_pts.clear()
	var num: int = randi_range(12, 18)
	var base_r: float = radius * 0.3
	for i in range(num):
		var angle: float = (TAU / num) * i + randf_range(-0.2, 0.2)
		var bulge: float = 0.6 + randf_range(0.2, 0.6)
		if randf() < 0.25:
			bulge *= 0.5
		var r: float = base_r * bulge
		_nucleus_pts.append(Vector2(cos(angle), sin(angle)) * r)

func _get_smooth_silhouette() -> PackedVector2Array:
	var smooth: PackedVector2Array = []
	var count: int = _silhouette_pts.size()
	for i in range(count):
		var curr: Vector2 = _silhouette_pts[i]
		var next: Vector2 = _silhouette_pts[(i + 1) % count]
		var prev: Vector2 = _silhouette_pts[(i - 1 + count) % count]
		smooth.append(curr.lerp(prev, 0.12))
		smooth.append(curr.lerp((prev + next) / 2.0, 0.06))
		smooth.append(curr.lerp(next, 0.12))
	return smooth

func _generate_tendrils() -> void:
	_tendrils.clear()
	for i in range(_tendril_count):
		var base_angle: float = (TAU / _tendril_count) * i + randf_range(-0.2, 0.2)
		var ctrl_points: Array = []
		for j in range(5):
			var t: float = float(j) / 4.0
			var r: float = radius * 0.12 + radius * 0.88 * t
			var angle: float = base_angle + randf_range(-0.4, 0.4) * (1.0 - t * 0.5)
			ctrl_points.append(Vector2(cos(angle), sin(angle)) * r)
		_tendrils.append({
			ctrl = ctrl_points,
			width_base = randf_range(5.0, 8.0),
			phase = randf_range(0.0, TAU),
			curl = randf_range(-0.4, 0.4)
		})

func _get_catmull_pts(ctrl: Array) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	var count: int = ctrl.size()
	for i in range(count - 1):
		var p0: Vector2 = ctrl[max(i-1, 0)]
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i+1]
		var p3: Vector2 = ctrl[min(i+2, count-1)]
		for s in range(8):
			var t: float = float(s) / 8.0
			var t2: float = t * t
			var t3: float = t2 * t
			var pt: Vector2 = (
				(-p0 + p1*3.0 - p2*3.0 + p3) * t3 +
				(p0*2.0 - p1*5.0 + p2*4.0 - p3) * t2 +
				(-p0 + p2) * t +
				p1 * 2.0
			) * 0.5
			pts.append(pt)
	pts.append(ctrl[count-1])
	return pts

func _process(delta: float) -> void:
	_time += delta
	_pulse_time += delta

	if _pulse_time >= _pulse_interval:
		_pulse_time = 0.0
		_pulse_radius = 0.0
		_pulse_alpha = 1.0
		_pulsing = true

	if _pulsing:
		_pulse_radius += radius * 1.2 * delta
		_pulse_alpha -= 0.7 * delta
		if _pulse_alpha <= 0:
			_pulsing = false

	if _hp_bar_timer > 0:
		_hp_bar_timer -= delta
		if _hp_bar_timer <= 0.5:
			_hp_bar_alpha = _hp_bar_timer / 0.5
	else:
		_hp_bar_alpha = 0.0

	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta

	queue_redraw()

func _draw() -> void:
	if _silhouette_pts.size() >= 3:
		var smooth: PackedVector2Array = _get_smooth_silhouette()
		var glow_pts: PackedVector2Array = []
		for p in smooth:
			glow_pts.append(p * 1.12)
		draw_colored_polygon(glow_pts, Color(0.4, 0.02, 0.02, 0.55))
		draw_colored_polygon(smooth, Color(0.45, 0.02, 0.02, 0.95))
	else:
		draw_circle(Vector2.ZERO, radius * 1.15, Color(0.4, 0.02, 0.02, 0.55))
		draw_circle(Vector2.ZERO, radius * 0.95, Color(0.45, 0.02, 0.02, 0.95))

	for tendril in _tendrils:
		var phase: float = tendril.phase
		var w_base: float = tendril.width_base
		var curl: float = tendril.curl

		var animated_ctrl: Array = []
		for k in range(tendril.ctrl.size()):
			var base_pt: Vector2 = tendril.ctrl[k]
			var t: float = float(k) / (tendril.ctrl.size() - 1)
			var wave: float = sin(_time * 2.2 + phase + k * 1.2) * (5.0 * t)
			wave += sin(_time * 1.5 + phase * 0.7 + k * 1.5) * (3.0 * t)
			var perp: Vector2 = base_pt.normalized().rotated(PI/2 + curl)
			animated_ctrl.append(base_pt + perp * wave)

		var pts: PackedVector2Array = _get_catmull_pts(animated_ctrl)
		var total_len: float = 0.0
		for i in range(pts.size() - 1):
			total_len += pts[i].distance_to(pts[i+1])

		var seg_len: float = 0.0
		for i in range(pts.size() - 1):
			seg_len += pts[i].distance_to(pts[i+1])
			var t: float = seg_len / total_len
			var w: float = w_base * (2.0 - 1.7 * t)
			w = max(w, 1.2)
			var outline_col: Color = Color(0.55, 0.02, 0.02, 0.98).lerp(Color(0.02, 0.0, 0.0, 0.98), 1.0 - t)
			draw_line(pts[i], pts[i+1], outline_col, w + 2.0)

		seg_len = 0.0
		for i in range(pts.size() - 1):
			seg_len += pts[i].distance_to(pts[i+1])
			var t: float = seg_len / total_len
			var w: float = w_base * (2.0 - 1.7 * t)
			w = max(w, 1.2)
			var line_col: Color = Color(0.65 + t * 0.1, 0.02, 0.02, 0.95).lerp(Color(0.03, 0.0, 0.0, 0.95), 1.0 - t)
			draw_line(pts[i], pts[i+1], line_col, w)

		if _pulsing:
			var pulse_pos: float = clampf(_pulse_radius / (radius * 1.2), 0.0, 1.0)
			var pulse_width: float = 0.28
			seg_len = 0.0
			for i in range(pts.size() - 1):
				seg_len += pts[i].distance_to(pts[i+1])
				var t: float = seg_len / total_len
				var dist_to_pulse: float = abs(t - pulse_pos)
				var pulse_glow: float = max(0.0, 1.0 - dist_to_pulse / pulse_width) * _pulse_alpha
				if pulse_glow > 0.02:
					var w: float = w_base * (2.0 - 1.7 * t) * 0.7
					w = max(w, 1.0)
					var glow_col: Color = Color(1.0, 0.35, 0.35, clampf(pulse_glow * 1.1, 0.0, 1.0)).lerp(Color(0.35, 0.02, 0.02, pulse_glow * 0.6), 1.0 - t)
					draw_line(pts[i], pts[i+1], Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * 0.5), w + 4.0)
					draw_line(pts[i], pts[i+1], glow_col, w)

	if _nucleus_pts.size() >= 3:
		var wobble: float = 0.02 * sin(_time * 2.5)
		var outer: PackedVector2Array = []
		var mid: PackedVector2Array = []
		var inner: PackedVector2Array = []
		for i in range(_nucleus_pts.size()):
			var p: Vector2 = _nucleus_pts[i]
			var s: float = 1.0 + wobble * sin(i * 1.3)
			outer.append(p * 1.05 * s)
			mid.append(p * 0.65 * s)
			inner.append(p * 0.35 * s)
		draw_colored_polygon(outer, Color(0.15, 0.0, 0.0, 1.0))
		draw_colored_polygon(mid, Color(0.55, 0.02, 0.02, 1.0))
		draw_colored_polygon(inner, Color(0.82, 0.08, 0.08, 0.95))
		var core_idx: int = _nucleus_pts.size() / 2
		var core_offset: Vector2 = _nucleus_pts[0].lerp(_nucleus_pts[core_idx], 0.3) * 0.15
		draw_circle(core_offset, radius * 0.06, Color(0.95, 0.25, 0.25, 0.85))
	else:
		draw_circle(Vector2.ZERO, radius * 0.32, Color(0.15, 0.0, 0.0, 1.0))
		draw_circle(Vector2.ZERO, radius * 0.22, Color(0.55, 0.02, 0.02, 1.0))
		draw_circle(Vector2.ZERO, radius * 0.13, Color(0.82, 0.08, 0.08, 0.95))
		draw_circle(Vector2(-radius * 0.08, -radius * 0.1), radius * 0.06, Color(0.95, 0.25, 0.25, 0.85))

	if _hp_bar_alpha > 0:
		var angle: float = -rotation
		var bar_w: float = 50.0
		var bar_h: float = 5.0
		var bar_offset: Vector2 = Vector2(0, -radius - 12).rotated(angle)
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
	_hp_bar_timer = 2.0
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

func _spawn_damage_number(amount: float) -> void:
	var label = Label.new()
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

func _drop_blood() -> void:
	var drop_scene = preload("res://scenes/BloodDrop.tscn")
	var coffin = get_tree().get_first_node_in_group("coffin")
	if not coffin:
		return
	var target_pos: Vector2 = coffin.global_position + coffin.size / 2
	for i in range(3):
		var drop = drop_scene.instantiate()
		get_parent().add_child(drop)
		var drop_value: float = max(1.0, max_hp / 60.0)
		drop.setup(global_position, drop_value, target_pos)
