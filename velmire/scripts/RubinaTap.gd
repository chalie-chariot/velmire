extends Node2D

## 심장 수정 용기형 탭 - 주기적으로 루비 생산, 클릭 시 UI로 흡수

var tap_index: int = 1        # 몇 번째 탭인지 (1~5)
var level: int = 1             # 현재 레벨 (1~3)
var accumulated: int = 0       # 현재 누적 루비
var is_producing: bool = false

# 탭 인덱스별 스탯 테이블
const TAP_STATS = {
	1: {"interval": 3.0, "cap": 5,  "chip_chance": 0.0},
	2: {"interval": 3.0, "cap": 8,  "chip_chance": 0.01},
	3: {"interval": 3.0, "cap": 8,  "chip_chance": 0.01},
	4: {"interval": 3.0, "cap": 12, "chip_chance": 0.03},
	5: {"interval": 3.0, "cap": 18, "chip_chance": 0.05},
}

# 레벨업 스탯 보정 (2번째 탭 이상)
const LEVEL_BONUS = {
	2: {"interval_mult": 0.75, "cap_add": 4},
	3: {"interval_mult": 0.55, "cap_add": 10},
}

const FILL_TWEEN_DUR: float = 0.3
const FLOAT_DUR: float = 0.4
const SPAWN_INTERVAL: float = 0.05
const RISE_TO_FLOAT_DUR: float = 0.15
const LABEL_COUNTDOWN_DUR: float = 0.35
const FIRE_INTERVAL: float = 0.06
const SQUASH_PRESS_DUR: float = 0.08
const SQUASH_RECOV_DUR: float = 0.15
const FILL_DRAIN_DUR: float = 0.2
const CHIP_FLASH_DUR: float = 0.3

var _production_timer: Timer
var _flask_rect: ColorRect
var _accum_label: Label
var _shader_mat: ShaderMaterial
var _time_accum: float = 0.0
var _is_at_cap: bool = false
var _collecting: bool = false
var _resources_added_this_cycle: bool = false


func get_cap() -> int:
	return _get_effective_cap()


func _ready() -> void:
	add_to_group("rubina_tap")
	_production_timer = $ProductionTimer
	_flask_rect = $FlaskRect
	_accum_label = $AccumLabel
	_shader_mat = _flask_rect.material as ShaderMaterial

	$ProductionTimer.timeout.connect(_on_production_timer_timeout)
	$Area2D.input_pickable = true

	# ProgressBar: Q탭 OwnedNodesContainer 슬롯 내에서만 표시
	if _is_in_q_tab_panel():
		$ProgressBar.visible = true

	_update_shader()
	_update_accum_label()

	_production_timer.wait_time = _get_effective_interval()
	_production_timer.start()


func _process(delta: float) -> void:
	_time_accum += delta
	_shader_mat.set_shader_parameter("time_val", _time_accum)

	var bar = _get_auto_progress_bar()
	if bar:
		if $ProductionTimer.is_stopped():
			bar.value = 100.0 if accumulated >= get_cap() else 0.0
		else:
			var progress: float = 1.0 - ($ProductionTimer.time_left / $ProductionTimer.wait_time)
			bar.value = progress * 100.0


func _update_shader() -> void:
	if not _shader_mat:
		return
	var cap_val: int = get_cap()
	_shader_mat.set_shader_parameter("fill_ratio", float(accumulated) / float(cap_val) if cap_val > 0 else 0.0)
	_shader_mat.set_shader_parameter("level", level)
	_shader_mat.set_shader_parameter("glow_intensity", 1.0 if accumulated >= get_cap() else 0.0)


func _on_accumulated_changed() -> void:
	if not _shader_mat:
		return
	var cap_val: int = get_cap()
	var target: float = float(accumulated) / float(cap_val) if cap_val > 0 else 0.0
	var from_val: Variant = _shader_mat.get_shader_parameter("fill_ratio")
	var from_f: float = target if typeof(from_val) != TYPE_FLOAT else float(from_val)
	var set_fill: Callable = func(v): _shader_mat.set_shader_parameter("fill_ratio", v)
	var tw: Tween = create_tween()
	tw.tween_method(set_fill, from_f, target, FILL_TWEEN_DUR).set_ease(Tween.EASE_OUT)
	_shader_mat.set_shader_parameter("level", level)
	_shader_mat.set_shader_parameter("glow_intensity", 1.0 if accumulated >= get_cap() else 0.0)


func _update_accum_label() -> void:
	if _accum_label:
		_accum_label.text = "%d/%d" % [accumulated, _get_effective_cap()]


func _play_accum_label_countdown(from: int) -> void:
	if not _accum_label:
		return
	var cap_val: int = _get_effective_cap()
	var set_label: Callable = func(v: float): _accum_label.text = "%d/%d" % [int(round(v)), cap_val]
	var tw: Tween = create_tween()
	tw.tween_method(set_label, float(from), 0.0, LABEL_COUNTDOWN_DUR).set_ease(Tween.EASE_OUT)


func _get_effective_interval() -> float:
	var base_stats = TAP_STATS.get(tap_index, TAP_STATS[1])
	var interval: float = base_stats.interval
	if level >= 2:
		var bonus = LEVEL_BONUS.get(level, {})
		interval *= bonus.get("interval_mult", 1.0)
	return interval


func _get_effective_cap() -> int:
	var base_stats = TAP_STATS.get(tap_index, TAP_STATS[1])
	var cap: int = base_stats.cap
	if level >= 2:
		var bonus = LEVEL_BONUS.get(level, {})
		cap += bonus.get("cap_add", 0)
	return cap


func _get_chip_chance() -> float:
	var base_stats = TAP_STATS.get(tap_index, TAP_STATS[1])
	return base_stats.get("chip_chance", 0.0)


func _start_production() -> void:
	if accumulated >= _get_effective_cap():
		return
	is_producing = true
	_production_timer.wait_time = _get_effective_interval()
	_production_timer.start()


func _on_production_timer_timeout() -> void:
	accumulated += 1
	_update_accum_label()
	_on_accumulated_changed()
	if accumulated >= get_cap():
		$ProductionTimer.stop()
		is_producing = false
		_is_at_cap = true
	else:
		_production_timer.wait_time = _get_effective_interval()
		_production_timer.start()


func _is_in_q_tab_panel() -> bool:
	var n: Node = self
	while n:
		if n.name == "OwnedNodesContainer":
			return true
		n = n.get_parent()
	return false


func _get_canvas_layer() -> CanvasLayer:
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("CanvasLayer") as CanvasLayer
	return get_tree().current_scene.get_node_or_null("CanvasLayer") as CanvasLayer


func _get_q_tab_target_screen_pos() -> Vector2:
	var main = get_tree().root.get_node_or_null("Main")
	if not main:
		return Vector2(88, 245)
	var q_open: bool = main.left_open

	var target_pos: Vector2
	if q_open:
		var ruby_value = main.get_node_or_null("CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/RubyRow/RubyValue")
		if ruby_value:
			target_pos = ruby_value.get_global_transform_with_canvas().origin
		else:
			target_pos = Vector2(20.0, 300.0)
	else:
		var blood_icon = main.get_node("CanvasLayer/LeftTab/Icon1")
		target_pos = blood_icon\
			.get_global_transform_with_canvas().origin + Vector2(15, 0)

	return target_pos


func _play_flask_squash_drain() -> void:
	var tw_sq: Tween = create_tween()
	tw_sq.tween_property(_flask_rect, "scale:y", 0.82, SQUASH_PRESS_DUR).set_ease(Tween.EASE_OUT)
	tw_sq.tween_property(_flask_rect, "scale:y", 1.0, SQUASH_RECOV_DUR).set_ease(Tween.EASE_OUT)
	var from_f: float = _shader_mat.get_shader_parameter("fill_ratio")
	if typeof(from_f) != TYPE_FLOAT:
		from_f = 0.0
	var set_fill: Callable = func(v): _shader_mat.set_shader_parameter("fill_ratio", v)
	var tw_fill: Tween = create_tween()
	tw_fill.tween_method(set_fill, from_f, 0.0, FILL_DRAIN_DUR).set_ease(Tween.EASE_OUT)


func _run_float_then_launch(lbl: Label, target_pos: Vector2, is_last: bool, rubies_to_add: int, chips_to_add: int) -> void:
	if not is_instance_valid(lbl):
		if is_last:
			_collecting = false
		return
	if not is_inside_tree():
		if is_last:
			_collecting = false
		return
	var base_y: float = lbl.position.y
	var float_tw = create_tween()
	if not float_tw:
		if is_last:
			_collecting = false
		return
	float_tw.set_loops(0)
	float_tw.tween_property(lbl, "position:y",
		base_y - randf_range(5.0, 9.0),
		randf_range(0.12, 0.18))\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	float_tw.tween_property(lbl, "position:y",
		base_y + randf_range(3.0, 6.0),
		randf_range(0.12, 0.18))\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	float_tw.tween_property(lbl, "position:y",
		base_y,
		randf_range(0.08, 0.12))\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	var lbl_launch = lbl
	var launch_cb = func():
		_launch_ruby(lbl_launch, target_pos, is_last, rubies_to_add, chips_to_add)
	float_tw.tween_callback(launch_cb)


func _launch_ruby(ruby: Label, target_pos: Vector2, is_last: bool, rubies_to_add: int, chips_to_add: int) -> void:
	if not is_instance_valid(ruby):
		if is_last:
			_collecting = false
		return
	if not is_inside_tree():
		if is_last:
			_collecting = false
		return
	var duration = randf_range(0.35, 0.45)
	var via = Vector2(
		lerpf(ruby.position.x, target_pos.x, 0.5) + randf_range(-40.0, 40.0),
		lerpf(ruby.position.y, target_pos.y, 0.5) + randf_range(-50.0, -20.0)
	)
	var tw = create_tween()
	if not tw:
		if is_last:
			_collecting = false
		return
	tw.tween_property(ruby, "position", via, duration * 0.5)\
		.set_ease(Tween.EASE_IN)
	tw.tween_property(ruby, "position", target_pos, duration * 0.5)\
		.set_ease(Tween.EASE_OUT)
	var arrive_cb = func():
		_on_ruby_arrive(ruby, target_pos, is_last, rubies_to_add, chips_to_add)
	tw.tween_callback(arrive_cb)


func _on_ruby_arrive(lbl: Label, target_pos: Vector2, is_last: bool, rubies_to_add: int, chips_to_add: int) -> void:
	_spawn_arrive_effect(target_pos)
	if is_last:
		if not _resources_added_this_cycle:
			_resources_added_this_cycle = true
			if rubies_to_add > 0:
				ResourceManager.add_ruby(rubies_to_add)
			if chips_to_add > 0:
				ResourceManager.add_chip(chips_to_add)
				_play_chip_flash()
		_collecting = false
	if not is_instance_valid(lbl):
		return
	var shrink_tw = create_tween()
	if not shrink_tw:
		lbl.queue_free()
		return
	shrink_tw.tween_property(lbl, "scale", Vector2.ZERO, 0.08).set_ease(Tween.EASE_IN)
	var free_cb = lbl.queue_free
	shrink_tw.tween_callback(free_cb)


func _spawn_arrive_effect(pos: Vector2) -> void:
	var canvas_layer = get_tree().root\
		.get_node("Main/CanvasLayer")
	var shader = load("res://shaders/arrive_effect.gdshader")

	# 1. 글로우 링 (크게)
	var ring = ColorRect.new()
	ring.size = Vector2(180.0, 180.0)
	ring.pivot_offset = Vector2(90.0, 90.0)
	ring.position = pos - Vector2(90.0, 90.0)
	ring.z_index = 100
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_mat = ShaderMaterial.new()
	ring_mat.shader = shader
	ring_mat.set_shader_parameter("effect_type", 0)
	ring_mat.set_shader_parameter("progress", 0.0)
	ring.material = ring_mat
	canvas_layer.add_child(ring)

	var rtw = create_tween()
	var ring_cb_prog = func(v: float):
		ring_mat.set_shader_parameter("progress", v)
	rtw.tween_method(ring_cb_prog, 0.0, 1.0, 0.7)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_EXPO)
	var ring_cb_free = func(): ring.queue_free()
	rtw.tween_callback(ring_cb_free)

	# 2. 빛줄기 (더 크게)
	var rays = ColorRect.new()
	rays.size = Vector2(220.0, 220.0)
	rays.pivot_offset = Vector2(110.0, 110.0)
	rays.position = pos - Vector2(110.0, 110.0)
	rays.z_index = 99
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rays_mat = ShaderMaterial.new()
	rays_mat.shader = shader
	rays_mat.set_shader_parameter("effect_type", 1)
	rays_mat.set_shader_parameter("progress", 0.0)
	rays.material = rays_mat
	canvas_layer.add_child(rays)

	var stw = create_tween()
	var rays_cb_prog = func(v: float):
		rays_mat.set_shader_parameter("progress", v)
	stw.tween_method(rays_cb_prog, 0.0, 1.0, 0.65)\
		.set_ease(Tween.EASE_OUT)
	var rays_cb_free = func(): rays.queue_free()
	stw.tween_callback(rays_cb_free)

	# 3. 파티클 (링 외곽에서 바깥으로 튀어나옴)
	for i in range(12):
		var dot = ColorRect.new()
		var dot_size = randf_range(3.5, 6.5)
		dot.size = Vector2(dot_size, dot_size)
		dot.pivot_offset = Vector2(dot_size / 2.0, dot_size / 2.0)
		dot.color = Color(
			randf_range(0.85, 1.0),
			randf_range(0.0, 0.2),
			randf_range(0.1, 0.3),
			1.0
		)
		dot.z_index = 101
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# 링 외곽(반경 20~30px)에서 시작
		var start_angle = (TAU / 12.0) * i \
			+ randf_range(-0.2, 0.2)
		var start_r = randf_range(15.0, 25.0)
		var start_pos = pos \
			+ Vector2(cos(start_angle), sin(start_angle)) \
			* start_r - Vector2(dot_size / 2.0, dot_size / 2.0)

		# 바깥으로 튀어나감
		var end_r = randf_range(45.0, 75.0)
		var end_pos = pos \
			+ Vector2(cos(start_angle), sin(start_angle)) \
			* end_r - Vector2(dot_size / 2.0, dot_size / 2.0)

		dot.position = start_pos
		canvas_layer.add_child(dot)

		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position",
			end_pos, randf_range(0.45, 0.65))\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_QUART)
		tw.tween_property(dot, "modulate:a",
			0.0, 0.4).set_delay(0.25)
		var dcb = func(): dot.queue_free()
		tw.tween_callback(dcb)


func _play_chip_flash() -> void:
	_flask_rect.modulate = Color(0.0, 1.0, 0.8, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(_flask_rect, "modulate", Color(1, 1, 1, 1), CHIP_FLASH_DUR).set_ease(Tween.EASE_OUT)


func get_chip_chance() -> float:
	return _get_chip_chance()


func _collect_rubies() -> void:
	if _collecting:
		return
	_collecting = true
	_resources_added_this_cycle = false

	var count: int = accumulated
	accumulated = 0
	_is_at_cap = false
	_play_accum_label_countdown(count)
	_production_timer.wait_time = _get_effective_interval()
	$ProductionTimer.start()

	var icon_count: int = mini(count, 7)
	var got_chip: bool = icon_count > 0 and randf() < get_chip_chance()
	var rubies_to_add: int = count - 1 if got_chip else count
	var chips_to_add: int = 1 if got_chip else 0

	var canvas_layer := _get_canvas_layer()
	if not canvas_layer:
		_collecting = false
		return

	var tap_canvas_origin: Vector2 = get_global_transform_with_canvas().origin
	var target_screen: Vector2 = _get_q_tab_target_screen_pos()

	# 1단계: 루비 생성 (0.05초 간격) → 상승 → 부유 (각자 독립) → 부유 완료 후 발사
	var icon_half: Vector2 = Vector2(7, 7)
	var target_adj: Vector2 = target_screen - icon_half

	for i in icon_count:
		await get_tree().create_timer(SPAWN_INTERVAL * i).timeout
		var spawn_at_tap: Vector2 = tap_canvas_origin + Vector2(randf_range(-12, 12), 0)
		var float_offset: Vector2 = Vector2(randf_range(-30, 30), randf_range(-120, -80))
		var float_pos: Vector2 = tap_canvas_origin + float_offset

		var lbl: Label = Label.new()
		lbl.text = "🔴"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.z_index = 10
		canvas_layer.add_child(lbl)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		lbl.position = spawn_at_tap

		var is_last_flag: bool = (i == icon_count - 1)
		var lbl_ref = lbl
		var rubies_val = rubies_to_add
		var chips_val = chips_to_add
		var rise_cb = func():
			_run_float_then_launch(lbl_ref, target_adj, is_last_flag, rubies_val, chips_val)
		var rise_tw: Tween = create_tween()
		rise_tw.tween_property(lbl, "position", float_pos, RISE_TO_FLOAT_DUR).set_ease(Tween.EASE_OUT)
		rise_tw.tween_callback(rise_cb)

	# 상승 완료 시점에 플라스크 반응
	await get_tree().create_timer(RISE_TO_FLOAT_DUR + 0.1).timeout
	_play_flask_squash_drain()


func _get_auto_progress_bar() -> ProgressBar:
	var main = get_tree().get_first_node_in_group("main")
	if main:
		return main.get_node_or_null("CanvasLayer/LeftPanel/Card2_Automation/AutoProgressBar") as ProgressBar
	return null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			var local_pos := to_local(get_global_mouse_position())
			var shape := $Area2D/CollisionShape2D.shape as CircleShape2D
			if shape and local_pos.length() <= shape.radius:
				if accumulated > 0 and not _collecting:
					if get_viewport():
						get_viewport().set_input_as_handled()
					_collect_rubies()
