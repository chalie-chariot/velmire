extends Node2D

var node_id: String = ""
var node_type: String = ""  # "흡혈" / "결계" / "증폭"
var node_color: Color = Color(1.0, 0.0, 0.0)
var _time: float = 0.0
var _base_points: PackedVector2Array = []
var radius: float = 28.0
var is_dragging: bool = false
var is_placed: bool = false
var grid_col: int = -1
var grid_row: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _slot_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_generate_base_points()

func _generate_base_points() -> void:
	_base_points.clear()
	var num: int = 32
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = radius
		_base_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_pos: Vector2 = to_local(get_global_mouse_position())
				if local_pos.length() <= radius + 10.0:
					is_dragging = true
					_drag_offset = global_position - get_global_mouse_position()
					_slot_position = global_position
					get_viewport().set_input_as_handled()
			else:
				if is_dragging:
					is_dragging = false
					_try_place_on_grid()

func _process(delta: float) -> void:
	_time += delta
	if is_dragging:
		global_position = get_global_mouse_position() + _drag_offset
	queue_redraw()

func _draw() -> void:
	var pts: PackedVector2Array = []
	for i in range(_base_points.size()):
		var base: Vector2 = _base_points[i]
		var wave: float = sin(_time * 1.2 + i * 0.3) * 0.8
		pts.append(base + base.normalized() * wave)

	# 글로우 4겹
	for g in range(4):
		var scale: float = 1.6 - g * 0.2
		var alpha: float = 0.06 - g * 0.01
		var glow_pts: PackedVector2Array = []
		for p in pts:
			glow_pts.append(p * scale)
		draw_colored_polygon(glow_pts,
			Color(node_color.r, node_color.g, node_color.b, alpha))

	# 외곽 어두운 테두리
	var outer_pts: PackedVector2Array = []
	for p in pts:
		outer_pts.append(p * 1.05)
	draw_colored_polygon(outer_pts,
		Color(node_color.r * 0.3, node_color.g * 0.3, node_color.b * 0.3, 1.0))

	# 본체
	draw_colored_polygon(pts,
		Color(node_color.r * 0.7, node_color.g * 0.7, node_color.b * 0.7, 1.0))

	# 내부 밝은 영역 (표면장력 느낌)
	var inner_pts: PackedVector2Array = []
	for p in pts:
		inner_pts.append(p * 0.65)
	draw_colored_polygon(inner_pts,
		Color(node_color.r, node_color.g, node_color.b, 1.0))

	# 하이라이트 (빛 반사 느낌)
	var hi_pts: PackedVector2Array = []
	for i in range(pts.size()):
		var angle: float = (2.0 * PI / pts.size()) * i
		if angle > PI * 1.2 and angle < PI * 1.9:
			hi_pts.append(pts[i] * 0.5 + Vector2(-radius * 0.1, -radius * 0.2))
	if hi_pts.size() >= 3:
		draw_colored_polygon(hi_pts, Color(1.0, 1.0, 1.0, 0.25))

	# 큰 반사광 (좌상단)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.28),
		radius * 0.28, Color(1.0, 1.0, 1.0, 0.18))
	# 작은 강한 반사광
	draw_circle(Vector2(-radius * 0.28, -radius * 0.32),
		radius * 0.12, Color(1.0, 1.0, 1.0, 0.7))
	# 극소 하이라이트
	draw_circle(Vector2(-radius * 0.3, -radius * 0.34),
		radius * 0.05, Color(1.0, 1.0, 1.0, 0.95))

	if is_dragging:
		draw_arc(Vector2.ZERO, radius * 1.35, 0, TAU, 64,
			Color(node_color.r, node_color.g, node_color.b, 0.7), 2.5)

func _try_place_on_grid() -> void:
	var grid = get_tree().get_first_node_in_group("heart_pulse")
	if not grid:
		return
	var cell: Vector2i = grid.world_to_grid(global_position)
	if grid.is_valid_cell(cell.x, cell.y) and grid.is_cell_empty(cell.x, cell.y):
		if is_placed and grid_col >= 0 and grid_row >= 0:
			grid.remove_node(grid_col, grid_row)
		global_position = grid.grid_to_world(cell.x, cell.y)
		grid.place_node(cell.x, cell.y, node_id)
		is_placed = true
		grid_col = cell.x
		grid_row = cell.y
	else:
		_return_to_slot()

func _return_to_slot() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", _slot_position, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
