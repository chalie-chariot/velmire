extends Node2D

var _connections: Array = []
var _pending: Node2D = null

func _ready() -> void:
	add_to_group("connection_manager")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if _pending:
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
	_pending.is_pending_connection = false
	_pending._is_first_selected = false
	_clear_highlights()
	_pending = null
	_notify_synergy_engine()
	queue_redraw()

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

func set_last_placed(_node: Node2D) -> void:
	pass  # 호환용 (GameNode _try_place_on_grid에서 호출)

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

func _draw() -> void:
	for conn in _connections:
		if not is_instance_valid(conn.from) or not is_instance_valid(conn.to):
			continue
		var a: Vector2 = to_local(conn.from.global_position)
		var b: Vector2 = to_local(conn.to.global_position)
		draw_line(a, b, Color(1.0, 0.2, 0.2, 0.25), 12.0)
		draw_line(a, b, Color(1.0, 0.3, 0.3, 0.45), 7.0)
		draw_line(a, b, Color(1.0, 0.5, 0.5, 0.85), 3.5)
		var mid: Vector2 = (a + b) / 2.0
		draw_circle(mid, 4.0, Color(1.0, 0.5, 0.5, 0.9))

	if _pending:
		var a: Vector2 = to_local(_pending.global_position)
		var b: Vector2 = to_local(get_global_mouse_position())
		draw_line(a, b, Color(1.0, 1.0, 1.0, 0.4), 2.0)

func _process(_delta: float) -> void:
	if not _connections.is_empty() or _pending:
		queue_redraw()
