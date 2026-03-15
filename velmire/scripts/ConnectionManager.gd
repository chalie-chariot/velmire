extends Node2D

var _connections: Array = []
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
	# A 노드 우클릭 시 해당 노드의 모든 연결 해제
	_connections = _connections.filter(func(conn):
		return conn.from != node and conn.to != node
	)
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
	if _synergy_flashing or not _connections.is_empty() or _pending:
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
