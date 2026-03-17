extends Node2D
class_name HeartPulse

const GRID_COLS: int = 24
const GRID_ROWS: int = 14
const CELL_SIZE: int = 80
const COFFIN_RANGE: float = 400.0  # 노드 배치 가능 관 주변 반경
const BUFF_DURATION: float = 5.0
const BUFF_COOLDOWN_MULT: float = 0.5
const BUFF_DAMAGE_MULT: float = 1.5
const BUFF_RANGE_MULT: float = 1.5
const BUFF_BLOOD_MULT: float = 2.0
const PULSE_HIT_TOLERANCE: float = 25.0
const PULSE_INTERVAL_NORMAL: float = 5.0
const PULSE_INTERVAL_DANGER: float = 3.5
const PULSE_INTERVAL_CRISIS: float = 2.0
const HP_DANGER_THRESHOLD: float = 0.5
const HP_CRISIS_THRESHOLD: float = 0.25

var grid_offset: Vector2 = Vector2.ZERO
var _current_interval: float = PULSE_INTERVAL_NORMAL
var _hit_lights: Array = []
var _coffin_center: Vector2 = Vector2(960, 540)
var grid: Array = []
var _pulse_time: float = 0.0
var _pulse_radius: float = 0.0
var _coffin_pulse_boost: bool = false
var _pulse_alpha: float = 0.0
var _pulsing: bool = false
var _max_pulse_radius: float = 1200.0

func _ready() -> void:
	add_to_group("heart_pulse")
	for r in range(GRID_ROWS):
		var row: Array = []
		for c in range(GRID_COLS):
			row.append(null)
		grid.append(row)

func setup(coffin_center: Vector2) -> void:
	grid_offset = Vector2(0, 0)
	_coffin_center = coffin_center
	queue_redraw()

func _process(delta: float) -> void:
	_update_pulse_interval()
	_pulse_time += delta
	if _pulse_time >= _current_interval:
		_pulse_time = 0.0
		_start_pulse()

	if _pulsing:
		_pulse_radius += 600.0 * delta
		var progress: float = _pulse_radius / _max_pulse_radius
		_pulse_alpha = pow(1.0 - progress, 1.5)
		_check_pulse_hit_ring_lights()
		if _pulse_radius >= _max_pulse_radius:
			print("파동 종료 — hit_lights 개수: ", _hit_lights.size())
			for h in _hit_lights:
				if is_instance_valid(h):
					print("hit 노드: ", h.name, " / 유효: true")
				else:
					print("hit 노드: 이미 소멸됨")
			_pulsing = false
			_pulse_alpha = 0.0
			_hit_lights.clear()
		queue_redraw()

func _start_pulse() -> void:
	_pulse_radius = 0.0
	_pulse_alpha = 1.0
	_pulsing = true
	_hit_lights.clear()

func _update_pulse_interval() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main or not main.has_method("get_coffin_hp_ratio"):
		return
	var hp_ratio: float = main.get_coffin_hp_ratio()
	var new_interval: float
	if hp_ratio <= HP_CRISIS_THRESHOLD:
		new_interval = PULSE_INTERVAL_CRISIS
	elif hp_ratio <= HP_DANGER_THRESHOLD:
		new_interval = PULSE_INTERVAL_DANGER
	else:
		new_interval = PULSE_INTERVAL_NORMAL
	if _coffin_pulse_boost:
		new_interval *= 0.8
	if new_interval != _current_interval:
		_current_interval = new_interval
		_on_interval_changed()

func _activate_coffin_pulse_boost() -> void:
	_coffin_pulse_boost = true

func _deactivate_coffin_pulse_boost() -> void:
	_coffin_pulse_boost = false

func _on_interval_changed() -> void:
	var coffin = get_tree().get_first_node_in_group("coffin")
	if not coffin:
		return
	var col: Color = Color(1.0, 0.3, 0.3, 1.0) if _current_interval <= PULSE_INTERVAL_CRISIS else Color(1.0, 0.6, 0.3, 1.0)
	var tw = create_tween()
	tw.tween_property(coffin, "modulate", col, 0.1)
	tw.tween_property(coffin, "modulate", Color(1, 1, 1, 1), 0.4)

func _check_pulse_hit_ring_lights() -> void:
	var lights = get_tree().get_nodes_in_group("ring_light")
	for light in lights:
		if light in _hit_lights:
			continue
		if not ("is_placed" in light and light.is_placed):
			continue
		var dist: float = _coffin_center.distance_to(light.global_position)
		if abs(_pulse_radius - dist) <= PULSE_HIT_TOLERANCE:
			_hit_lights.append(light)
			_apply_buff_to_ring_light(light)
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for node in nodes:
		if node in _hit_lights:
			continue
		if not ("is_placed" in node and node.is_placed):
			continue
		var ndist: float = _coffin_center.distance_to(node.global_position)
		if abs(_pulse_radius - ndist) <= PULSE_HIT_TOLERANCE:
			print("파동 히트 노드: ", node.name, " / node_type: ", node.get("node_type"), " / is_placed: ", node.get("is_placed"), " / is_dragging: ", node.get("is_dragging"))
			_hit_lights.append(node)
			if node.has_method("trigger_pulse_bonus"):
				node.trigger_pulse_bonus()

func _apply_buff_to_ring_light(light: Node) -> void:
	if not light.get("_buff_ready"):
		return
	var buff_type: int = randi() % 4
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	var buffed_nodes: Array = []
	for node in nodes:
		if node.get("_is_being_dragged") == true:
			continue
		if node.get("is_placed") == false:
			continue
		if node.global_position.distance_to(light.global_position) <= 300.0:
			buffed_nodes.append(node)
	if buffed_nodes.is_empty():
		return
	for node in buffed_nodes:
		if not node.has_method("apply_buff"):
			continue
		match buff_type:
			0:
				node.apply_buff("cooldown", BUFF_COOLDOWN_MULT, BUFF_DURATION)
			1:
				node.apply_buff("damage", BUFF_DAMAGE_MULT, BUFF_DURATION)
			2:
				node.apply_buff("range", BUFF_RANGE_MULT, BUFF_DURATION)
			3:
				node.apply_buff("blood", BUFF_BLOOD_MULT, BUFF_DURATION)
	if light.has_method("on_buff_received"):
		light.on_buff_received(buff_type, buffed_nodes)

func get_max_blood_mult() -> float:
	var max_mult: float = 1.0
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for node in nodes:
		if node.has_method("get_buff_blood_mult"):
			var m: float = node.get_buff_blood_mult()
			if m > max_mult:
				max_mult = m
	return max_mult

func _draw() -> void:
	# 관 범위 원형 외곽선 (항상 표시)
	draw_arc(_coffin_center, COFFIN_RANGE, 0, TAU, 128,
		Color(1.0, 0.4, 0.4, 0.2), 1.5)

	var max_dist: float = 800.0
	var min_alpha: float = 0.03
	var max_alpha: float = 0.25

	for r in range(GRID_ROWS + 1):
		var y: float = r * CELL_SIZE
		var row_center: Vector2 = Vector2(960, y)
		var dist: float = row_center.distance_to(_coffin_center)
		var alpha: float = lerp(max_alpha, min_alpha, clamp(dist / max_dist, 0.0, 1.0))
		draw_line(Vector2(0, y), Vector2(GRID_COLS * CELL_SIZE, y), Color(1.0, 0.2, 0.2, alpha), 1.0)

	for c in range(GRID_COLS + 1):
		var x: float = c * CELL_SIZE
		var col_center: Vector2 = Vector2(x, 540)
		var dist: float = col_center.distance_to(_coffin_center)
		var alpha: float = lerp(max_alpha, min_alpha, clamp(dist / max_dist, 0.0, 1.0))
		draw_line(Vector2(x, 0), Vector2(x, GRID_ROWS * CELL_SIZE), Color(1.0, 0.2, 0.2, alpha), 1.0)

	if _pulsing and _pulse_alpha > 0:
		const BLUR_SPREAD: float = 45.0  # 블러 퍼짐 거리 (픽셀)
		const BLUR_LAYERS: int = 12     # 겹쳐 그리는 링 수

		# 메인 파동 링 — 빛의 산란처럼 여러 링을 겹쳐 블러 효과
		for i in range(BLUR_LAYERS):
			var offset: float = (float(i) / (BLUR_LAYERS - 1) - 0.5) * BLUR_SPREAD * 2.0
			var r: float = _pulse_radius + offset
			if r < 0:
				continue
			var dist_from_peak: float = abs(offset) / BLUR_SPREAD
			var layer_alpha: float = _pulse_alpha * exp(-dist_from_peak * dist_from_peak * 2.0)
			draw_arc(_coffin_center, r, 0, TAU, 128,
				Color(1.0, 0.2, 0.2, layer_alpha * 0.6), 4.0)

		# 잔광 링 4개 — 마찬가지로 블러 처리
		for i in range(1, 5):
			var trail_r: float = _pulse_radius - i * 50.0
			if trail_r < 0:
				continue
			var trail_a: float = _pulse_alpha * (1.0 - i * 0.2) * 0.4
			for j in range(8):
				var bo: float = (float(j) / 7.0 - 0.5) * 25.0
				var br: float = trail_r + bo
				if br < 0:
					continue
				var b_dist: float = abs(bo) / 25.0
				var ba: float = trail_a * exp(-b_dist * b_dist * 2.0)
				draw_arc(_coffin_center, br, 0, TAU, 128,
					Color(1.0, 0.15, 0.15, ba), 2.0)

		for r in range(GRID_ROWS + 1):
			var y: float = r * CELL_SIZE
			for c in range(GRID_COLS):
				var seg_center: Vector2 = Vector2(
					c * CELL_SIZE + CELL_SIZE / 2, y
				)
				var dist: float = seg_center.distance_to(_coffin_center)
				var diff: float = _pulse_radius - dist
				if diff >= 0 and diff < 120.0:
					var glow: float = (1.0 - diff / 120.0) * _pulse_alpha * 1.2
					glow = clamp(glow, 0.0, 1.0)
					draw_line(
						Vector2(c * CELL_SIZE, y),
						Vector2((c + 1) * CELL_SIZE, y),
						Color(1.0, 0.3, 0.3, glow), 2.5
					)

		for c in range(GRID_COLS + 1):
			var x: float = c * CELL_SIZE
			for r in range(GRID_ROWS):
				var seg_center: Vector2 = Vector2(
					x, r * CELL_SIZE + CELL_SIZE / 2
				)
				var dist: float = seg_center.distance_to(_coffin_center)
				var diff: float = _pulse_radius - dist
				if diff >= 0 and diff < 120.0:
					var glow: float = (1.0 - diff / 120.0) * _pulse_alpha * 1.2
					glow = clamp(glow, 0.0, 1.0)
					draw_line(
						Vector2(x, r * CELL_SIZE),
						Vector2(x, (r + 1) * CELL_SIZE),
						Color(1.0, 0.3, 0.3, glow), 2.5
					)

func world_to_grid(pos: Vector2) -> Vector2i:
	var col: int = int((pos.x - grid_offset.x) / CELL_SIZE)
	var row: int = int((pos.y - grid_offset.y) / CELL_SIZE)
	return Vector2i(col, row)

func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(
		grid_offset.x + col * CELL_SIZE + CELL_SIZE / 2,
		grid_offset.y + row * CELL_SIZE + CELL_SIZE / 2
	)

func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < GRID_COLS and row >= 0 and row < GRID_ROWS

func is_cell_empty(col: int, row: int) -> bool:
	return grid[row][col] == null

func place_node(col: int, row: int, node_id: String) -> bool:
	if not is_valid_cell(col, row):
		return false
	if not is_cell_empty(col, row):
		return false
	grid[row][col] = node_id
	return true

func remove_node(col: int, row: int) -> void:
	if is_valid_cell(col, row):
		grid[row][col] = null
