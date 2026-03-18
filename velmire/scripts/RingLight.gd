extends Node2D

const LIFETIME = 60.0
const WARNING_TIME = 12.0  # 20% = 12초
const RANGE_RADIUS: float = 300.0
const BUFF_COLORS: Array = [
	Color(0.4, 0.5, 1.0, 1.0),
	Color(1.0, 0.4, 0.1, 1.0),
	Color(0.2, 1.0, 0.4, 1.0),
	Color(1.0, 0.9, 0.1, 1.0),
]
const BUFF_ICONS: Array = ["⏱", "⚔", "🔵", "🩸"]
const BUFF_NAMES: Array = ["쿨다운 감소", "데미지 증가", "범위 확장", "혈액 증가"]
const BUFF_COOLDOWN: float = 10.0

var range_radius: float = RANGE_RADIUS
var ring_size: float = 30.0
var hole_size: float = 12.0
var is_placed: bool = false
var is_dragging: bool = false

var _countdown: Node = null
var _cooldown_arc: Node = null
var _time_left: float = LIFETIME
var _expired: bool = false
var _buff_cooldown_left: float = 0.0
var _buff_ready: bool = true
var shader_index: int = -1

func _ready() -> void:
	add_to_group("ring_light")
	_build_visual()

func _build_visual() -> void:
	var outer = Panel.new()
	outer.size = Vector2(ring_size * 2, ring_size * 2)
	outer.position = -Vector2(ring_size, ring_size)
	outer.pivot_offset = Vector2(ring_size, ring_size)
	var os = StyleBoxFlat.new()
	os.set_corner_radius_all(int(ring_size))
	os.bg_color = Color(1.0, 0.9, 0.6, 0.9)
	outer.add_theme_stylebox_override("panel", os)
	add_child(outer)

	var inner = Panel.new()
	inner.size = Vector2(hole_size * 2, hole_size * 2)
	inner.position = -Vector2(hole_size, hole_size)
	var ins = StyleBoxFlat.new()
	ins.set_corner_radius_all(int(hole_size))
	ins.bg_color = Color(0.05, 0.0, 0.0, 1.0)
	inner.add_theme_stylebox_override("panel", ins)
	add_child(inner)

	var range_line = Line2D.new()
	range_line.default_color = Color(1.0, 0.9, 0.6, 0.3)
	range_line.width = 1.5
	range_line.antialiased = true
	for p in range(65):
		var a = (TAU / 64) * p
		range_line.add_point(Vector2(cos(a), sin(a)) * range_radius)
	add_child(range_line)

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_viewport().get_mouse_position()
		return

	if not is_placed or _expired:
		return

	if not _buff_ready:
		_buff_cooldown_left -= delta
		if _buff_cooldown_left <= 0.0:
			_buff_ready = true
			_buff_cooldown_left = 0.0
			if _cooldown_arc and is_instance_valid(_cooldown_arc):
				_cooldown_arc.update_ratio(0.0)
				_cooldown_arc.modulate = Color(1, 1, 1, 0)
		elif _cooldown_arc and is_instance_valid(_cooldown_arc):
			var ratio: float = _buff_cooldown_left / BUFF_COOLDOWN
			_cooldown_arc.update_ratio(ratio)

	_time_left -= delta
	var ratio: float = clampf(_time_left / LIFETIME, 0.0, 1.0)
	if _countdown and is_instance_valid(_countdown):
		_countdown.update_ratio(ratio)

	if _time_left <= 0.0:
		_expire()

func _input(event: InputEvent) -> void:
	if is_placed:
		return
	# 우클릭 또는 ESC: 배치 취소 (차감 없이 제거)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			queue_free()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			_try_place()
			return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		if get_viewport():
			get_viewport().set_input_as_handled()

func _try_place() -> void:
	# 배치 성공 조건 통과 후 루비 차감
	if ResourceManager.ruby < 2:
		var main = get_tree().get_first_node_in_group("main")
		if main:
			main._show_deny_popup("루비 부족 🔴2 필요")
		queue_free()
		return

	ResourceManager.spend_ruby(2)
	is_placed = true
	_time_left = LIFETIME
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main._register_ring_light(self)
	_on_placed()
	_start_pulse()

func _start_pulse() -> void:
	var is_warn: bool = _time_left <= WARNING_TIME
	_emit_pulse(is_warn)
	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_pulse_timer_timeout)
	add_child(timer)

func _on_pulse_timer_timeout() -> void:
	var is_warn: bool = _time_left <= WARNING_TIME
	_emit_pulse(is_warn)

func _emit_pulse(is_warning: bool) -> void:
	var col: Color = Color(0.0, 0.9, 0.85, 0.6)  # 청록
	if is_warning:
		col = Color(1.0, 0.15, 0.2, 0.6)  # 빨강
	var pts: int = 64
	var center_pos: Vector2 = global_position

	for wave in range(2):
		var pulse = Line2D.new()
		pulse.default_color = Color(col.r, col.g, col.b, 0.0)
		pulse.width = 3.0
		pulse.antialiased = true
		for p in range(pts + 1):
			var a = (TAU / pts) * p
			pulse.add_point(center_pos + Vector2(cos(a), sin(a)) * 5.0)
		get_parent().add_child(pulse)

		var wave_delay: float = wave * 0.3
		var updater = _make_pulse_updater(pulse, pts, center_pos, col)

		var tw = create_tween()
		tw.tween_interval(wave_delay)
		tw.tween_method(updater, 0.0, 1.0, 2.5)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_on_pulse_done.bind(pulse))

func _make_pulse_updater(pulse: Line2D, pts: int, center_pos: Vector2, base_col: Color) -> Callable:
	return func(t: float) -> void:
		if not is_instance_valid(pulse):
			return
		var r: float = lerpf(5.0, range_radius * 1.15, t)
		var alpha: float
		if t < 0.15:
			alpha = lerpf(0.0, 0.7, t / 0.15)
		else:
			alpha = lerpf(0.7, 0.0, (t - 0.15) / 0.85)
		pulse.default_color = Color(base_col.r, base_col.g, base_col.b, alpha)
		pulse.width = lerpf(4.0, 0.3, t)
		for i in range(pts + 1):
			var a: float = (TAU / pts) * i
			pulse.set_point_position(i, center_pos + Vector2(cos(a), sin(a)) * r)

func _on_pulse_done(pulse: Line2D) -> void:
	if is_instance_valid(pulse):
		pulse.queue_free()


func _on_placed() -> void:
	_spawn_countdown()


func _spawn_countdown() -> void:
	var scene = load("res://scenes/RingCountdown.tscn") as PackedScene
	_countdown = scene.instantiate()
	_countdown.global_position = global_position
	get_parent().add_child(_countdown)


func _get_my_index() -> int:
	var lights = get_tree().get_nodes_in_group("ring_light")
	var placed: Array = []
	for l in lights:
		if "is_placed" in l and l.is_placed:
			placed.append(l)
	for i in range(placed.size()):
		if placed[i] == self:
			return i
	return -1


func _expire() -> void:
	_expired = true
	if _countdown and is_instance_valid(_countdown) and _countdown.has_method("start_fadeout"):
		_countdown.start_fadeout()

	# 링라이트 범위 내 노드 유효성 재검사
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n.has_method("_check_validity"):
			n._check_validity()

	# 링라이트 페이드아웃
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	var cb = func() -> void: queue_free()
	tw.tween_callback(cb)


func _spawn_cooldown_arc() -> void:
	var scene = load("res://scenes/RingCountdown.tscn") as PackedScene
	_cooldown_arc = scene.instantiate()
	_cooldown_arc.set_meta("small", true)
	_cooldown_arc.set_meta("no_warning", true)
	_cooldown_arc.global_position = global_position
	get_parent().add_child(_cooldown_arc)
	_cooldown_arc.update_ratio(1.0)


func on_buff_received(buff_type: int, buffed_nodes: Array) -> void:
	_buff_ready = false
	_buff_cooldown_left = BUFF_COOLDOWN
	if _cooldown_arc == null or not is_instance_valid(_cooldown_arc):
		_spawn_cooldown_arc()
	if _cooldown_arc and is_instance_valid(_cooldown_arc):
		_cooldown_arc.modulate = Color(1, 1, 1, 1)
		_cooldown_arc.update_ratio(1.0)
	var col: Color = BUFF_COLORS[buff_type] if buff_type < BUFF_COLORS.size() else Color.WHITE
	var main = get_tree().get_first_node_in_group("main")
	var canvas_layer: Node = main.get_node("CanvasLayer") if main else null

	# 1. 링라이트 순간 발광
	var tw = create_tween()
	tw.tween_property(self, "modulate", col * 2.0, 0.1)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

	# 2. 링라이트 → 노드 빛줄기 방사
	for node in buffed_nodes:
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = Color(col.r, col.g, col.b, 0.8)
		line.add_point(global_position)
		line.add_point(node.global_position)
		get_parent().add_child(line)
		var ltw = create_tween()
		ltw.tween_property(line, "modulate:a", 0.0, 0.4)
		var lcb = func() -> void: line.queue_free()
		ltw.tween_callback(lcb)
		if canvas_layer:
			_spawn_buff_icon(node, buff_type, canvas_layer)

	# 3. 버프 종류 텍스트 팝업
	if canvas_layer:
		_spawn_buff_popup(buff_type, canvas_layer)


func _spawn_buff_icon(node: Node, buff_type: int, canvas_layer: Node) -> void:
	var icon = Label.new()
	icon.text = BUFF_ICONS[buff_type] if buff_type < BUFF_ICONS.size() else "?"
	icon.add_theme_font_size_override("font_size", 18)
	icon.modulate = BUFF_COLORS[buff_type] if buff_type < BUFF_COLORS.size() else Color.WHITE
	icon.z_index = 100
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start_pos: Vector2 = node.get_global_transform_with_canvas().origin - Vector2(10, 30)
	icon.position = start_pos
	canvas_layer.add_child(icon)
	var itw = create_tween()
	itw.set_parallel(true)
	itw.tween_property(icon, "position:y", start_pos.y - 20, 5.0).set_ease(Tween.EASE_OUT)
	itw.tween_property(icon, "modulate:a", 0.0, 1.0).set_delay(4.0)
	itw.set_parallel(false)
	var icb = func() -> void: icon.queue_free()
	itw.tween_callback(icb)


func _spawn_buff_popup(buff_type: int, canvas_layer: Node) -> void:
	var popup = Label.new()
	popup.text = (BUFF_NAMES[buff_type] if buff_type < BUFF_NAMES.size() else "버프") + "!"
	popup.add_theme_font_size_override("font_size", 16)
	popup.modulate = BUFF_COLORS[buff_type] if buff_type < BUFF_COLORS.size() else Color.WHITE
	popup.z_index = 100
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var start_pos: Vector2 = get_global_transform_with_canvas().origin - Vector2(40, 60)
	popup.position = start_pos
	canvas_layer.add_child(popup)
	var ptw = create_tween()
	ptw.set_parallel(true)
	ptw.tween_property(popup, "position:y", start_pos.y - 30, 0.6).set_ease(Tween.EASE_OUT)
	ptw.tween_property(popup, "modulate:a", 0.0, 0.6).set_delay(0.3)
	ptw.set_parallel(false)
	var pcb = func() -> void: popup.queue_free()
	ptw.tween_callback(pcb)
