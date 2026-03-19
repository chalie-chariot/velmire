extends Node2D

var _connections: Array = []
var _coffin_connections: Array = []
var _coffin_pulse_boost: bool = false
var _pending: Node2D = null
var _selected: Node2D = null  # 일반 클릭으로 선택된 노드 (SHIFT 누르면 범위 표시)
var _flow_time: float = 0.0
var _synergy_flash_time: float = 0.0
var _synergy_flashing: bool = false

func _ready() -> void:
	add_to_group("connection_manager")

func _input(event: InputEvent) -> void:
	# 시너지 연결 대기 중 우클릭 → 연결 취소만 (노드 제거 안 함, 이벤트 소비로 Main에서 on_right_click 호출 방지)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _pending != null:
			_pending.is_pending_connection = false
			_pending._is_first_selected = false
			_clear_highlights()
			_pending = null
			queue_redraw()
			if get_viewport():
				get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if _pending:
				_pending.is_pending_connection = false
				_pending._is_first_selected = false
				_clear_highlights()
				_pending = null
			else:
				_selected = null
				var main = get_tree().get_first_node_in_group("main")
				if main and main.has_method("clear_all_node_selection"):
					main.clear_all_node_selection()
			queue_redraw()
		elif event.keycode == KEY_SHIFT:
			if event.pressed:
				if _pending == null and _selected:
					# 일반 클릭 후 SHIFT 누름 → 범위 표시
					start_connect(_selected)
					_selected = null
			else:
				# SHIFT 뗌 → 범위 해제 (누르는 동안에만 유지)
				if _pending:
					_selected = _pending  # 다음 SHIFT에서 바로 범위 표시되도록 복원
					_pending.is_pending_connection = false
					_pending._is_first_selected = false
					_clear_highlights()
					_pending = null
					queue_redraw()

func start_connect(node: Node2D) -> void:
	# 같은 노드 재클릭 → 취소
	if _pending == node:
		_pending.is_pending_connection = false
		_pending._is_first_selected = false
		_clear_highlights()
		_pending = null
		queue_redraw()
		return
	# A 노드 선택 (첫 번째)
	if _pending != null:
		_pending.is_pending_connection = false
		_pending._is_first_selected = false
		_clear_highlights()
	_pending = node
	node.is_pending_connection = true
	node._is_first_selected = true
	_highlight_nearby_nodes(node)

func finish_connect(node: Node2D) -> void:
	# B 노드 선택 (두 번째) → 연결
	if _pending == null or _pending == node:
		return

	# 동일 타입 노드끼리는 시너지 연결 불가
	if _pending.node_type == node.node_type:
		_pending.is_pending_connection = false
		_pending._is_first_selected = false
		_clear_highlights()
		_pending = null
		queue_redraw()
		return

	# 이미 연결된 쌍이면 무시
	for conn in _connections:
		if (conn.from == _pending and conn.to == node) or \
		   (conn.from == node and conn.to == _pending):
			_pending.is_pending_connection = false
			_pending._is_first_selected = false
			_clear_highlights()
			_pending = null
			queue_redraw()
			return

	_connections.append({from = _pending, to = node})
	var from_node: Node2D = _pending
	_pending.is_pending_connection = false
	_pending._is_first_selected = false
	_clear_highlights()
	_pending = null

	# 연결 이펙트
	_spawn_connect_effect(from_node, node)
	if from_node.has_method("trigger_connect_pulse"):
		from_node.trigger_connect_pulse()
	if node.has_method("trigger_connect_pulse"):
		node.trigger_connect_pulse()

	_notify_synergy_engine()
	queue_redraw()

func _spawn_connect_effect(from_node: Node2D, to_node: Node2D) -> void:
	var effect = Node2D.new()
	effect.set_script(preload("res://scripts/SynergyConnectEffect.gd"))
	from_node.get_parent().add_child(effect)
	effect.setup(
		from_node.global_position,
		to_node.global_position,
		from_node.node_color,
		to_node.node_color
	)

func disconnect_from(node: Node2D) -> void:
	# A 노드 우클릭 시 해당 노드의 모든 연결 해제 (노드-노드 + 관-노드)
	var keep_conn = func(conn):
		return conn.from != node and conn.to != node
	_connections = _connections.filter(keep_conn)
	_disconnect_from_coffin(node)
	node.is_pending_connection = false
	node._is_first_selected = false
	if _pending == node:
		_pending = null
	_clear_highlights()
	_notify_synergy_engine()
	queue_redraw()

func disconnect_node(node: Node2D) -> void:
	disconnect_from(node)

func get_pending() -> Node2D:
	return _pending

func set_selected(node: Node2D) -> void:
	_selected = node

func clear_selected() -> void:
	_selected = null

func set_last_placed(node: Node2D) -> void:
	_selected = node  # 최근 배치 노드 → SHIFT 누르면 해당 노드 연결 범위 표시

func _highlight_nearby_nodes(source: Node2D) -> void:
	var nodes = source.get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n == source:
			continue
		if source.global_position.distance_to(n.global_position) < 400.0:
			n.is_highlighted = true

func _clear_highlights() -> void:
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		n.is_highlighted = false
		n._is_first_selected = false

func get_connections_for(node: Node2D) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.from == node:
			result.append(conn.to)
		elif conn.to == node:
			result.append(conn.from)
	return result

func _notify_synergy_engine() -> void:
	var se = get_tree().get_first_node_in_group("synergy_engine")
	if se and se.has_method("check_synergies"):
		se.check_synergies(self)

func trigger_synergy_flash() -> void:
	_synergy_flash_time = 0.0
	_synergy_flashing = true

func _process(delta: float) -> void:
	_flow_time += delta
	if _synergy_flashing:
		_synergy_flash_time += delta
		if _synergy_flash_time > 0.4:
			_synergy_flashing = false
	# 관-노드 혈관 곡선은 각 노드의 vein_timer 콜백에서 갱신됨
	if _synergy_flashing or not _connections.is_empty() or _pending or not _coffin_connections.is_empty():
		queue_redraw()

func _draw() -> void:
	for conn in _connections:
		if not is_instance_valid(conn.from) or not is_instance_valid(conn.to):
			continue
		var a: Vector2 = to_local(conn.from.global_position)
		var b: Vector2 = to_local(conn.to.global_position)
		var mid: Vector2 = (a + b) / 2.0
		var dir: Vector2 = (b - a).normalized()
		var perp: Vector2 = Vector2(-dir.y, dir.x)

		var segments: int = 40
		var all_pts: PackedVector2Array = []

		for i in range(segments + 1):
			var t: float = float(i) / segments
			var pos: Vector2 = a.lerp(b, t)
			var envelope: float = sin(t * PI) * 5.0
			var wave: float = sin(t * 8.0 - _flow_time * 3.0) * envelope
			pos += perp * wave
			all_pts.append(pos)

		var mid_idx: int = segments / 2

		# 글로우 (가장 두꺼운 레이어)
		for i in range(all_pts.size() - 1):
			var t: float = float(i) / all_pts.size()
			var c: Color
			if i < mid_idx:
				c = Color(conn.from.node_color.r, conn.from.node_color.g,
					conn.from.node_color.b, 0.12)
			else:
				c = Color(conn.to.node_color.r, conn.to.node_color.g,
					conn.to.node_color.b, 0.12)
			draw_line(all_pts[i], all_pts[i+1], c, 16.0)

		# 중간 레이어
		for i in range(all_pts.size() - 1):
			var c: Color
			if i < mid_idx:
				c = Color(conn.from.node_color.r * 0.6,
					conn.from.node_color.g * 0.6,
					conn.from.node_color.b * 0.6, 0.5)
			else:
				c = Color(conn.to.node_color.r * 0.6,
					conn.to.node_color.g * 0.6,
					conn.to.node_color.b * 0.6, 0.5)
			draw_line(all_pts[i], all_pts[i+1], c, 8.0)

		# 본체 (밝은 핵심)
		for i in range(all_pts.size() - 1):
			var t: float = float(i) / all_pts.size()
			# 노드 안쪽(밝은색) → 바깥(어두운색) 표현
			var brightness: float = 1.0 - abs(t - 0.5) * 0.6
			var c: Color
			if i < mid_idx:
				c = Color(conn.from.node_color.r * brightness,
					conn.from.node_color.g * brightness,
					conn.from.node_color.b * brightness, 0.9)
			else:
				c = Color(conn.to.node_color.r * brightness,
					conn.to.node_color.g * brightness,
					conn.to.node_color.b * brightness, 0.9)
			draw_line(all_pts[i], all_pts[i+1], c, 4.0)

		# 중간점 (시너지 컬러 블렌드)
		var mid_wave: Vector2 = all_pts[mid_idx]
		var mid_color: Color = Color(
			(conn.from.node_color.r + conn.to.node_color.r) / 2.0,
			(conn.from.node_color.g + conn.to.node_color.g) / 2.0,
			(conn.from.node_color.b + conn.to.node_color.b) / 2.0, 0.9)
		draw_circle(mid_wave, 5.0, Color(mid_color.r, mid_color.g, mid_color.b, 0.8))
		draw_circle(mid_wave, 3.0, mid_color)

		# 시너지 발동 시 연결선 번쩍 (시너지 컬러)
		if _synergy_flashing:
			var flash: float = 1.0 - (_synergy_flash_time / 0.4)
			for i in range(all_pts.size() - 1):
				var t: float = float(i) / all_pts.size()
				var c: Color
				if i < mid_idx:
					c = Color(conn.from.node_color.r, conn.from.node_color.g,
						conn.from.node_color.b, flash * 0.6)
				else:
					c = Color(conn.to.node_color.r, conn.to.node_color.g,
						conn.to.node_color.b, flash * 0.6)
				draw_line(all_pts[i], all_pts[i+1], c, 8.0)

	if _pending:
		var a: Vector2 = to_local(_pending.global_position)
		var b: Vector2 = to_local(get_global_mouse_position())
		var pc: Color = _pending.node_color
		draw_line(a, b, Color(pc.r, pc.g, pc.b, 0.4), 2.0)

func try_connect_to_coffin(node: Node) -> void:
	# upgrade_level 0 = 기본 / 1 = Lv.2 / 2 = Lv.3
	# Lv.2 = upgrade_level 1 이상부터 허용
	if node.get("upgrade_level") == null or node.upgrade_level < 1:
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("_show_deny_popup"):
			main._show_deny_popup("Lv.2 이상 노드만 연결 가능합니다")
		return

	if node in _coffin_connections:
		_disconnect_from_coffin(node)
		return

	if _coffin_connections.size() >= 3:
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("_show_deny_popup"):
			main._show_deny_popup("관 연결은 최대 3개입니다")
		return

	_coffin_connections.append(node)
	_apply_coffin_synergy(node)
	_draw_coffin_connection_line(node)

func _disconnect_from_coffin(node: Node) -> void:
	_coffin_connections.erase(node)
	_remove_coffin_synergy(node)
	_remove_coffin_connection_line(node)

func _apply_coffin_synergy(node: Node) -> void:
	var type = node.get("node_type")
	if type != null and type != "":
		node.set_meta("type", type)
	if "node_color" in node:
		node.set_meta("color", node.node_color)
	match type:
		"흡혈":
			node.set_meta("coffin_synergy", "heal")
		"결계":
			node.set_meta("coffin_synergy", "barrier")
			var main = get_tree().get_first_node_in_group("main")
			if main and main.has_method("_activate_coffin_barrier"):
				main._activate_coffin_barrier()
		"증폭":
			node.set_meta("coffin_synergy", "pulse")
			_coffin_pulse_boost = true
			var hp = get_tree().get_first_node_in_group("heart_pulse")
			if hp and hp.has_method("_activate_coffin_pulse_boost"):
				hp._activate_coffin_pulse_boost()

func _remove_coffin_synergy(node: Node) -> void:
	var type = node.get("node_type")
	match type:
		"결계":
			var any_barrier_left = false
			for n in _coffin_connections:
				if n.get("node_type") == "결계":
					any_barrier_left = true
					break
			if not any_barrier_left:
				var main = get_tree().get_first_node_in_group("main")
				if main and main.has_method("_deactivate_coffin_barrier"):
					main._deactivate_coffin_barrier()
		"증폭":
			var any_pulse_left = false
			for n in _coffin_connections:
				if n.get("node_type") == "증폭":
					any_pulse_left = true
					break
			if not any_pulse_left:
				_coffin_pulse_boost = false
				var hp = get_tree().get_first_node_in_group("heart_pulse")
				if hp and hp.has_method("_deactivate_coffin_pulse_boost"):
					hp._deactivate_coffin_pulse_boost()
	node.remove_meta("coffin_synergy")
	if node.has_meta("type"):
		node.remove_meta("type")
	if node.has_meta("color"):
		node.remove_meta("color")

func _draw_coffin_connection_line(node: Node) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return
	var entity_layer = main.get_node_or_null("EntityLayer")
	if not entity_layer:
		return
	var coffin = get_tree().get_first_node_in_group("coffin")
	if not coffin:
		return

	var coffin_center: Vector2 = coffin.global_position  # Coffin position = 중심 (960, 540)

	# 연결된 노드의 실제 색상 참조
	var line_color: Color
	if node.has_meta("color"):
		line_color = node.get_meta("color")
	else:
		line_color = node.modulate

	# 외곽 혈관 Line2D
	var line = Line2D.new()
	line.width = 14.0
	line.default_color = Color(line_color.r * 0.6, line_color.g * 0.6, line_color.b * 0.6, 0.85)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	entity_layer.add_child(line)
	node.set_meta("coffin_line", line)

	# 내부 라인 (외곽 위에, 노드 타입 색상 더 밝게)
	var inner_line = Line2D.new()
	inner_line.width = 5.0
	var inner_color: Color = line_color.lightened(0.2)
	inner_color.a = 0.7
	inner_line.default_color = inner_color
	inner_line.joint_mode = Line2D.LINE_JOINT_ROUND
	inner_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	inner_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	entity_layer.add_child(inner_line)
	node.set_meta("coffin_inner_line", inner_line)
	node.move_to_front()

	# 잔 라인 3개 생성
	var side_lines: Array = []
	var s_phase_mults: Array = [randf_range(0.8, 1.4), randf_range(0.8, 1.4), randf_range(0.8, 1.4)]
	var s_amps: Array = [randf_range(25.0, 50.0), randf_range(25.0, 50.0), randf_range(25.0, 50.0)]
	for i in range(3):
		var sline = Line2D.new()
		sline.width = 3.0
		var scolor: Color = line_color
		scolor.a = randf_range(0.2, 0.4)
		sline.default_color = scolor
		sline.joint_mode = Line2D.LINE_JOINT_ROUND
		sline.begin_cap_mode = Line2D.LINE_CAP_ROUND
		sline.end_cap_mode = Line2D.LINE_CAP_ROUND
		entity_layer.add_child(sline)
		side_lines.append(sline)
		node.set_meta("coffin_side_line_%d" % i, sline)

	# 제어점 흔들림용 오프셋 (배열로 감싸서 클로저 안에서 수정 가능)
	var offset := [0.0]

	# 매 프레임 곡선 업데이트 타이머 (line에 부착)
	var timer = Timer.new()
	timer.wait_time = 0.016  # ~60fps
	timer.autostart = true

	var cb = func() -> void:
		if not is_instance_valid(node) or not is_instance_valid(line) or not is_instance_valid(inner_line):
			timer.queue_free()
			return
		offset[0] += 0.05  # 잔 라인 흔들림용
		var start: Vector2 = entity_layer.to_local(node.global_position)
		var end: Vector2 = entity_layer.to_local(coffin_center)
		var mid: Vector2 = (start + end) * 0.5
		var perp: Vector2 = (end - start).rotated(PI * 0.5).normalized()
		var wave: float = 40.0  # 고정 진폭
		var ctrl1: Vector2 = mid + perp * wave
		var ctrl2: Vector2 = mid - perp * wave * 0.5

		# 3차 베지어 곡선 점 생성 (외곽 + 내부 동일)
		line.clear_points()
		inner_line.clear_points()
		for i in range(30):
			var t: float = float(i) / 29.0
			var p: Vector2 = (1 - t) * (1 - t) * (1 - t) * start + 3 * (1 - t) * (1 - t) * t * ctrl1 + 3 * (1 - t) * t * t * ctrl2 + t * t * t * end
			line.add_point(p)
			inner_line.add_point(p)

		# 잔 라인 업데이트
		for si in range(side_lines.size()):
			var sline = side_lines[si]
			if not is_instance_valid(sline):
				continue
			var s_offset: float = sin(offset[0] * s_phase_mults[si] + si * 2.1) * s_amps[si]
			sline.clear_points()
			for i in range(30):
				var t: float = float(i) / 29.0
				var p: Vector2 = (1 - t) * (1 - t) * (1 - t) * start + 3 * (1 - t) * (1 - t) * t * ctrl1 + 3 * (1 - t) * t * t * ctrl2 + t * t * t * end
				p += perp * s_offset * sin(t * PI)
				sline.add_point(p)

	timer.timeout.connect(cb)
	line.add_child(timer)

	# 2초마다 펄스 생성
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.autostart = true
	line.add_child(spawn_timer)
	var spawn_cb = func() -> void:
		if is_instance_valid(line) and is_instance_valid(inner_line):
			_spawn_vein_pulse(line, inner_line, entity_layer)
	spawn_timer.timeout.connect(spawn_cb)

func _spawn_vein_pulse(line: Line2D, inner_line: Line2D, entity_layer: Node2D) -> void:
	var progress := [1.0]  # 관(끝)에서 시작 → 노드(시작)로
	var pulse_timer = Timer.new()
	pulse_timer.wait_time = 0.016
	line.add_child(pulse_timer)

	var cb = func() -> void:
		if not is_instance_valid(line) or not is_instance_valid(inner_line):
			pulse_timer.queue_free()
			return
		progress[0] -= 0.02
		if progress[0] < 0.0:
			pulse_timer.queue_free()
			var default_curve = Curve.new()
			default_curve.add_point(Vector2(0.0, 1.0))
			default_curve.add_point(Vector2(1.0, 1.0))
			line.width_curve = default_curve
			line.width = 14.0
			inner_line.width_curve = default_curve
			inner_line.width = 5.0
			return

		var curve = Curve.new()
		curve.add_point(Vector2(0.0, 0.3))
		curve.add_point(Vector2(max(progress[0] - 0.1, 0.0), 0.3))
		curve.add_point(Vector2(progress[0], 1.0))
		curve.add_point(Vector2(min(progress[0] + 0.1, 1.0), 0.3))
		curve.add_point(Vector2(1.0, 0.3))
		line.width_curve = curve
		line.width = 28.0
		inner_line.width_curve = curve
		inner_line.width = line.width * 0.4

	pulse_timer.timeout.connect(cb)
	pulse_timer.start()

func _remove_coffin_connection_line(node: Node) -> void:
	for i in range(3):
		var meta_key := "coffin_side_line_%d" % i
		if node.has_meta(meta_key):
			var sline = node.get_meta(meta_key)
			if is_instance_valid(sline):
				sline.queue_free()
			node.remove_meta(meta_key)
	if node.has_meta("coffin_inner_line"):
		var inner = node.get_meta("coffin_inner_line")
		if is_instance_valid(inner):
			inner.queue_free()
		node.remove_meta("coffin_inner_line")
	if node.has_meta("coffin_line"):
		var line = node.get_meta("coffin_line")
		if is_instance_valid(line):
			line.queue_free()
		node.remove_meta("coffin_line")
