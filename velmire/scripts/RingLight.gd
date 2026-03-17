extends Node2D

const LIFETIME = 60.0
const WARNING_TIME = 20.0
const RANGE_RADIUS: float = 300.0

var range_radius: float = RANGE_RADIUS
var ring_size: float = 30.0
var hole_size: float = 12.0
var is_placed: bool = false
var is_dragging: bool = false

var _time_left: float = LIFETIME
var _warning_started: bool = false
var _expired: bool = false
var _warning_tween: Tween = null
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

	_time_left -= delta

	if _time_left <= WARNING_TIME and not _warning_started:
		_warning_started = true
		_start_countdown()

	if _warning_started:
		var ratio = _time_left / WARNING_TIME
		_update_countdown_visual(ratio)

	if _time_left <= 0.0:
		_expire()

func _input(event: InputEvent) -> void:
	if is_placed:
		return
	# 우클릭 또는 ESC: 배치 취소 (차감 없이 제거)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			queue_free()
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			_try_place()
			return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()

func _try_place() -> void:
	var coffin = get_tree().get_first_node_in_group("coffin")
	if coffin:
		var coffin_center: Vector2 = coffin.global_position + coffin.size / 2.0
		var dist: float = global_position.distance_to(coffin_center)
		print("링라이트 위치: ", global_position)
		print("관 global_position: ", coffin.global_position)
		print("관 size: ", coffin.size)
		print("관 중심: ", coffin_center)
		print("거리: ", dist)
		if dist > 700.0:
			print("배치 거부 — 거리 초과")
			var main = get_tree().get_first_node_in_group("main")
			if main:
				main._show_deny_popup("설치 범위를 벗어났습니다")
			queue_free()
			return

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
	_start_pulse()

func _start_pulse() -> void:
	_emit_pulse()
	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_pulse_timer_timeout)
	add_child(timer)

func _on_pulse_timer_timeout() -> void:
	_emit_pulse()

func _emit_pulse() -> void:
	var pts = 64
	var center_pos = global_position

	for wave in range(2):
		var pulse = Line2D.new()
		pulse.default_color = Color(1.0, 0.9, 0.6, 0.0)
		pulse.width = 3.0
		pulse.antialiased = true
		for p in range(pts + 1):
			var a = (TAU / pts) * p
			pulse.add_point(center_pos + Vector2(cos(a), sin(a)) * 5.0)
		get_parent().add_child(pulse)

		var wave_delay = wave * 0.3
		var updater = _make_pulse_updater(pulse, pts, center_pos)

		var tw = create_tween()
		tw.tween_interval(wave_delay)
		tw.tween_method(updater, 0.0, 1.0, 2.5
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_on_pulse_done.bind(pulse))

func _make_pulse_updater(pulse: Line2D, pts: int, center_pos: Vector2) -> Callable:
	return func(t: float):
		if not is_instance_valid(pulse):
			return
		var r = lerp(5.0, range_radius * 1.15, t)
		var alpha: float
		if t < 0.15:
			alpha = lerp(0.0, 0.7, t / 0.15)
		else:
			alpha = lerp(0.7, 0.0, (t - 0.15) / 0.85)
		pulse.default_color = Color(1.0, 0.95, 0.7, alpha)
		pulse.width = lerp(4.0, 0.3, t)
		for i in range(pts + 1):
			var a = (TAU / pts) * i
			pulse.set_point_position(i, center_pos + Vector2(cos(a), sin(a)) * r)

func _on_pulse_done(pulse: Line2D) -> void:
	if is_instance_valid(pulse):
		pulse.queue_free()


func _start_countdown() -> void:
	_start_warning_pulse()


func _start_warning_pulse() -> void:
	_warning_tween = create_tween()
	_warning_tween.set_loops()
	_warning_tween.tween_property(self, "modulate",
		Color(1.5, 0.3, 0.3, 1.0), 0.3)
	_warning_tween.tween_property(self, "modulate",
		Color(1.0, 1.0, 1.0, 1.0), 0.3)


func _update_countdown_visual(ratio: float) -> void:
	var idx = shader_index
	if idx < 0:
		idx = _get_my_index()
		if idx >= 0:
			shader_index = idx
	if idx < 0:
		return
	var base_radius = 300.0  # RANGE_RADIUS와 동일
	var current_radius = base_radius * ratio
	var overlay = get_tree().get_first_node_in_group("map_vignette_overlay")
	if overlay and overlay.material:
		overlay.material.set_shader_parameter(
			"bright_radius_" + str(idx),
			current_radius
		)


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
	var idx = shader_index
	if idx < 0:
		idx = _get_my_index()
	_expired = true

	# 링라이트 만료 시 모든 배치된 노드 유효성 재검사
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n.has_method("_check_validity"):
			n._check_validity()

	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()
	if idx >= 0:
		var overlay = get_tree().get_first_node_in_group("map_vignette_overlay")
		if overlay and overlay.material:
			overlay.material.set_shader_parameter(
				"bright_radius_" + str(idx), 0.0
			)

	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)\
		.set_ease(Tween.EASE_IN)
	var cb = func(): queue_free()
	tw.tween_callback(cb)
