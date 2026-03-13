class_name NodeGrid
extends Node2D

## 슬롯당 최대 1개 노드
const SLOT_SIZE := 64
const GRID_SIZE := 9
const TOTAL_SLOTS := 81

signal node_placed(node_id: String, slot_pos: Vector2i)
signal connection_made(node_a: String, node_b: String)

var _slots: Array[Dictionary] = []
var _slot_positions: Array[Vector2] = []
var _grid: GridContainer
var _node_slots: Node2D
var _is_connecting: bool = false
var _connect_source_slot: Vector2i = Vector2i(-1, -1)
var _drag_node_id: String = ""
var _drag_slot: Vector2i = Vector2i(-1, -1)
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	print("NodeGrid 시작")
	_grid = get_node_or_null("Grid") as GridContainer
	_node_slots = get_node_or_null("NodeSlots") as Node2D
	
	_init_grid_slots()
	_create_slot_visuals()
	queue_redraw()


func _init_grid_slots() -> void:
	_slots.clear()
	_slot_positions.clear()
	
	for i in range(TOTAL_SLOTS):
		var x := i % GRID_SIZE
		var y := i / GRID_SIZE
		var pos := Vector2(x * SLOT_SIZE, y * SLOT_SIZE)
		_slot_positions.append(pos)
		_slots.append({
			"node_id": "",
			"occupied": false
		})


func _create_slot_visuals() -> void:
	if not _grid:
		return
	
	for child in _grid.get_children():
		child.queue_free()
	
	for i in range(TOTAL_SLOTS):
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.set_meta("slot_index", i)
		panel.gui_input.connect(_on_slot_gui_input.bind(i))
		_grid.add_child(panel)


func _get_slot_from_position(global_pos: Vector2) -> Vector2i:
	var local := to_local(global_pos)
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	var gx := int(local.x / SLOT_SIZE)
	var gy := int(local.y / SLOT_SIZE)
	if gx >= GRID_SIZE or gy >= GRID_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


func _get_slot_index(slot_pos: Vector2i) -> int:
	if slot_pos.x < 0 or slot_pos.y < 0 or slot_pos.x >= GRID_SIZE or slot_pos.y >= GRID_SIZE:
		return -1
	return slot_pos.y * GRID_SIZE + slot_pos.x


func _draw() -> void:
	for i in range(TOTAL_SLOTS):
		var pos := _slot_positions[i]
		draw_rect(Rect2(pos, Vector2(SLOT_SIZE, SLOT_SIZE)), Color(0.2, 0.2, 0.2, 0.5))
		draw_rect(Rect2(pos, Vector2(SLOT_SIZE, SLOT_SIZE)), Color(0.4, 0.4, 0.4), false, 1.0)


## 노드 드래그 앤 드롭 배치
func place_node(node_id: String, slot_pos: Vector2i) -> bool:
	var idx := _get_slot_index(slot_pos)
	if idx < 0:
		return false
	if _slots[idx].occupied:
		return false
	
	_slots[idx].occupied = true
	_slots[idx].node_id = node_id
	node_placed.emit(node_id, slot_pos)
	queue_redraw()
	return true


func remove_node(slot_pos: Vector2i) -> bool:
	var idx := _get_slot_index(slot_pos)
	if idx < 0:
		return false
	if not _slots[idx].occupied:
		return false
	
	_slots[idx].occupied = false
	_slots[idx].node_id = ""
	queue_redraw()
	return true


func get_node_at_slot(slot_pos: Vector2i) -> String:
	var idx := _get_slot_index(slot_pos)
	if idx < 0:
		return ""
	return _slots[idx].get("node_id", "")


func get_slot_position(slot_pos: Vector2i) -> Vector2:
	var idx := _get_slot_index(slot_pos)
	if idx < 0:
		return Vector2.ZERO
	return _slot_positions[idx] + Vector2(SLOT_SIZE, SLOT_SIZE) / 2.0


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	var slot_pos := Vector2i(slot_index % GRID_SIZE, slot_index / GRID_SIZE)
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if mb.pressed:
			if mb.shift_pressed:
				if not _is_connecting:
					_start_connection(slot_pos)
				else:
					_complete_connection(slot_pos)
			else:
				_try_start_drag(slot_pos)
		else:
			if _drag_node_id != "":
				_finish_drag(slot_pos)
	
	elif event is InputEventMouseMotion and _drag_node_id != "":
		pass


func _start_connection(slot_pos: Vector2i) -> void:
	var node_id := get_node_at_slot(slot_pos)
	if node_id.is_empty():
		return
	_is_connecting = true
	_connect_source_slot = slot_pos


func _complete_connection(slot_pos: Vector2i) -> void:
	if not _is_connecting:
		return
	
	if slot_pos == _connect_source_slot:
		_is_connecting = false
		_connect_source_slot = Vector2i(-1, -1)
		return
	
	var node_a := get_node_at_slot(_connect_source_slot)
	var node_b := get_node_at_slot(slot_pos)
	if node_a.is_empty() or node_b.is_empty():
		_is_connecting = false
		_connect_source_slot = Vector2i(-1, -1)
		return
	
	connection_made.emit(node_a, node_b)
	_is_connecting = false
	_connect_source_slot = Vector2i(-1, -1)


func _try_start_drag(slot_pos: Vector2i) -> void:
	var node_id := get_node_at_slot(slot_pos)
	if node_id.is_empty():
		return
	
	var slot_center := get_slot_position(slot_pos)
	var global_center := to_global(slot_center)
	_drag_offset = get_global_mouse_position() - global_center
	_drag_node_id = node_id
	_drag_slot = slot_pos
	remove_node(slot_pos)


func _finish_drag(target_slot: Vector2i) -> void:
	if _drag_node_id.is_empty():
		return
	
	if place_node(_drag_node_id, target_slot):
		pass
	else:
		place_node(_drag_node_id, _drag_slot)
	
	_drag_node_id = ""
	_drag_slot = Vector2i(-1, -1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE:
			if _is_connecting:
				_is_connecting = false
				_connect_source_slot = Vector2i(-1, -1)
			elif _drag_node_id != "":
				place_node(_drag_node_id, _drag_slot)
				_drag_node_id = ""
				_drag_slot = Vector2i(-1, -1)
	elif event is InputEventMouseButton and _drag_node_id != "":
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			var release_slot := _get_slot_from_position(mb.global_position)
			if _get_slot_index(release_slot) >= 0:
				_finish_drag(release_slot)
			else:
				place_node(_drag_node_id, _drag_slot)
				_drag_node_id = ""
				_drag_slot = Vector2i(-1, -1)
