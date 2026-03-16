extends Node2D

var range_radius: float = 250.0
var ring_size: float = 30.0
var hole_size: float = 12.0
var is_placed: bool = false
var is_dragging: bool = false

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

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if is_placed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			_try_place()

func _try_place() -> void:
	var coffin = get_tree().get_first_node_in_group("coffin")
	if coffin:
		var dist = global_position.distance_to(coffin.global_position)
		if dist > 700.0:
			var main = get_tree().get_first_node_in_group("main")
			if main:
				main._show_deny_popup("설치 범위를 벗어났습니다")
			queue_free()
			return
	is_placed = true
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main._register_ring_light(self)
	print("_try_place - _start_pulse 호출 전")
	_start_pulse()
	print("_try_place - _start_pulse 호출 후")

func _start_pulse() -> void:
	print("_start_pulse 호출됨")
	_emit_pulse()

	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_pulse_timer_timeout)
	add_child(timer)
	print("타이머 추가됨:", timer)

func _on_pulse_timer_timeout() -> void:
	print("타이머 발동")
	_emit_pulse()

func _emit_pulse() -> void:
	var pts = 64
	var center_pos = global_position
	var pulse = Line2D.new()
	pulse.default_color = Color(1.0, 0.9, 0.6, 0.8)
	pulse.width = 3.0
	pulse.antialiased = true
	for p in range(pts + 1):
		var a = (TAU / pts) * p
		pulse.add_point(center_pos + Vector2(cos(a), sin(a)) * 10.0)
	get_parent().add_child(pulse)

	var updater = _make_pulse_updater(pulse, pts, center_pos)
	var tw = create_tween()
	tw.tween_method(updater, 0.0, 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_on_pulse_done.bind(pulse)).set_delay(2.0)

func _make_pulse_updater(pulse: Line2D, pts: int, center_pos: Vector2) -> Callable:
	return func(t: float):
		if not is_instance_valid(pulse):
			return
		var r = lerp(10.0, range_radius, t)
		pulse.default_color = Color(1.0, 0.9, 0.6, lerp(0.8, 0.0, t))
		pulse.width = lerp(3.0, 0.5, t)
		for i in range(pts + 1):
			var a = (TAU / pts) * i
			pulse.set_point_position(i, center_pos + Vector2(cos(a), sin(a)) * r)

func _on_pulse_done(pulse: Line2D) -> void:
	if is_instance_valid(pulse):
		pulse.queue_free()
