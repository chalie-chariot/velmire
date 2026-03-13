extends Node2D

var _connections: Array = []
var _pending: Node2D = null

func _ready() -> void:
	add_to_group("connection_manager")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and _pending:
			_pending.is_pending_connection = false
			_pending = null
			queue_redraw()

func _draw() -> void:
	for conn in _connections:
		if not is_instance_valid(conn.from) or not is_instance_valid(conn.to):
			continue
		var a: Vector2 = to_local(conn.from.global_position)
		var b: Vector2 = to_local(conn.to.global_position)
		var c: Color = conn.from.node_color

		# 글로우 레이어
		draw_line(a, b, Color(c.r, c.g, c.b, 0.25), 12.0)
		draw_line(a, b, Color(c.r, c.g, c.b, 0.45), 7.0)
		# 본체
		draw_line(a, b, Color(c.r, c.g, c.b, 0.85), 3.5)

		# 중간점
		var mid: Vector2 = (a + b) / 2.0
		draw_circle(mid, 4.0, Color(c.r, c.g, c.b, 0.9))

	if _pending:
		var a: Vector2 = to_local(_pending.global_position)
		var b: Vector2 = to_local(get_global_mouse_position())
		draw_line(a, b, Color(1.0, 1.0, 1.0, 0.4), 2.0)

func _process(_delta: float) -> void:
	if _pending:
		queue_redraw()

func try_connect(node: Node2D) -> void:
	if _pending == null:
		_pending = node
		node.is_pending_connection = true
		return

	if _pending == node:
		_pending.is_pending_connection = false
		_pending = null
		return

	for conn in _connections:
		if (conn.from == _pending and conn.to == node) or \
		   (conn.from == node and conn.to == _pending):
			_connections.erase(conn)
			_pending.is_pending_connection = false
			_pending = null
			_notify_synergy_engine()
			queue_redraw()
			return

	_connections.append({from = _pending, to = node})
	_pending.is_pending_connection = false
	_pending = null
	_notify_synergy_engine()
	queue_redraw()

func disconnect_node(node: Node2D) -> void:
	_connections = _connections.filter(func(conn):
		return conn.from != node and conn.to != node
	)
	if _pending == node:
		_pending.is_pending_connection = false
		_pending = null
	_notify_synergy_engine()
	queue_redraw()

func _notify_synergy_engine() -> void:
	var se = get_tree().get_first_node_in_group("synergy_engine")
	if se and se.has_method("check_synergies"):
		se.check_synergies(self)

func get_connections_for(node: Node2D) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.from == node:
			result.append(conn.to)
		elif conn.to == node:
			result.append(conn.from)
	return result
