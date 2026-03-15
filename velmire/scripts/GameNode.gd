extends Node2D

var node_id: String = ""
var node_type: String = ""  # "흡혈" / "결계" / "증폭"
var node_color: Color = Color(1.0, 0.0, 0.0)
var _time: float = 0.0
var _base_points: PackedVector2Array = []
const CONNECT_RANGE := 400.0  # 시너지 연결 가능 거리

var radius: float = 28.0
var is_dragging: bool = false
var is_placed: bool = false
var is_starter_node: bool = false  # 초기 무료 노드 2개 (취소 환불 제외)
var grid_col: int = -1
var grid_row: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _slot_position: Vector2 = Vector2.ZERO
var attack_cooldown: float = 3.0
var _attack_timer: float = 0.0
var _has_attacked_once: bool = false  # 첫 공격 후에만 쿨다운 게이지 표시
var synergy_double_damage: bool = false
var synergy_fast_cooldown: bool = false
var synergy_wide_slow: bool = false
var synergy_active: bool = false
var _phase_offset: float = 0.0
var is_hovered: bool = false
var is_highlighted: bool = false
var is_pending_connection: bool = false
var _shift_held: bool = false
var _is_first_selected: bool = false
var is_selected: bool = false
var _mouse_down_for_click: bool = false
var _mouse_down_pos: Vector2 = Vector2.ZERO

const _DRAG_THRESHOLD: float = 10.0

func _ready() -> void:
	_generate_base_points()
	_phase_offset = randf_range(0.0, TAU)
	add_to_group("game_nodes")
	if node_type == "흡혈":
		attack_cooldown = 2.0

func _generate_base_points() -> void:
	_base_points.clear()
	var num: int = 32
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = radius
		_base_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _start_drag() -> void:
	var prev_col := grid_col
	var prev_row := grid_row
	if is_placed:
		var grid = get_tree().get_first_node_in_group("heart_pulse")
		if grid and prev_col >= 0 and prev_row >= 0:
			grid.remove_node(prev_col, prev_row)
		is_placed = false
		grid_col = -1
		grid_row = -1
	is_dragging = true
	_drag_offset = global_position - get_global_mouse_position()
	_slot_position = global_position

func _deselect_all_others() -> void:
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n != self:
			n.is_selected = false

func _is_topmost_hovered() -> bool:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = to_local(mouse_pos)

	# 내 원 안에 있는지 먼저 확인
	if local_pos.length() > radius + 10.0:
		return false

	# 같은 원 안에 있는 다른 노드 중
	# 씬 트리에서 나보다 나중에 추가된 노드(위에 그려진) 있으면 false
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n == self:
			continue
		var n_local: Vector2 = n.to_local(mouse_pos)
		if n_local.length() <= n.radius + 10.0:
			# 둘 다 클릭 범위 안 → 씬 트리 순서로 판단
			if n.get_index() > get_index():
				return false
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var local_pos = to_local(get_global_mouse_position())
		var is_hover: bool = local_pos.length() <= radius + 10.0

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not Input.is_key_pressed(KEY_SHIFT):
				# 모든 노드의 _is_first_selected 강제 초기화
				var all_nodes = get_tree().get_nodes_in_group("game_nodes")
				for n in all_nodes:
					n._is_first_selected = false
					n.is_pending_connection = false
				# ConnectionManager pending 초기화
				var cm = get_tree().get_first_node_in_group("connection_manager")
				if cm and cm._pending != null:
					cm._pending.is_pending_connection = false
					cm._pending._is_first_selected = false
					cm._clear_highlights()
					cm._pending = null
					cm.queue_redraw()

			if is_hover and _is_topmost_hovered():
				if Input.is_key_pressed(KEY_SHIFT) and is_placed:
					# SHIFT + 좌클릭
					var cm = get_tree().get_first_node_in_group("connection_manager")
					if cm:
						if cm.get_pending() == null:
							cm.start_connect(self)
						else:
							cm.finish_connect(self)
					get_viewport().set_input_as_handled()
				elif not Input.is_key_pressed(KEY_SHIFT):
					if is_selected:
						# 이미 선택된 노드 재클릭 → 선택 해제
						var cm_sel = get_tree().get_first_node_in_group("connection_manager")
						if cm_sel and cm_sel.has_method("clear_selected"):
							cm_sel.clear_selected()
						is_selected = false
					else:
						# 클릭 vs 드래그 구분: 우선 대기
						_mouse_down_for_click = true
						_mouse_down_pos = get_global_mouse_position()
					get_viewport().set_input_as_handled()
			else:
				# 다른 곳 클릭 시 선택 해제
				var cm_sel = get_tree().get_first_node_in_group("connection_manager")
				if cm_sel and cm_sel.has_method("clear_selected"):
					cm_sel.clear_selected()
				is_selected = false

		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				is_dragging = false
				_try_place_on_grid()
				is_selected = false  # 드래그로 이동했을 때는 외곽선 숨김
				get_viewport().set_input_as_handled()
			elif _mouse_down_for_click and is_hover and _is_topmost_hovered():
				# 클릭만 했을 때 → 선택 (외곽선 표시)
				_deselect_all_others()
				is_selected = true
				var cm_sel = get_tree().get_first_node_in_group("connection_manager")
				if cm_sel and cm_sel.has_method("set_selected"):
					cm_sel.set_selected(self)
				_mouse_down_for_click = false
				get_viewport().set_input_as_handled()
			else:
				_mouse_down_for_click = false

	if event is InputEventMouseMotion and _mouse_down_for_click:
		var dist: float = _mouse_down_pos.distance_to(get_global_mouse_position())
		if dist > _DRAG_THRESHOLD:
			_mouse_down_for_click = false
			var cm_motion = get_tree().get_first_node_in_group("connection_manager")
			if cm_motion and cm_motion.has_method("clear_selected"):
				cm_motion.clear_selected()
			_start_drag()
			get_viewport().set_input_as_handled()

	if event is InputEventKey:
		if event.keycode == KEY_SHIFT:
			_shift_held = event.pressed

func _process(delta: float) -> void:
	_time += delta
	if is_dragging:
		global_position = get_global_mouse_position() + _drag_offset

	if is_placed:
		_attack_timer += delta
		if _attack_timer >= attack_cooldown:
			_attack_timer = 0.0
			_has_attacked_once = _do_attack()  # 적중 시에만 true, 빗나가면 false로 숨김

	var mouse_dist: float = to_local(get_global_mouse_position()).length()
	is_hovered = mouse_dist <= radius + 10.0

	queue_redraw()

func _draw() -> void:
	var pts: PackedVector2Array = []
	for i in range(_base_points.size()):
		var base: Vector2 = _base_points[i]
		# 느리고 부드럽게 출렁이는 물방울
		var wave: float = sin(_time * 0.7 + i * 0.5 + _phase_offset) * 1.8 \
			+ sin(_time * 1.1 + i * 0.8 + _phase_offset * 1.3) * 0.6
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

	if is_hovered:
		draw_arc(Vector2.ZERO, radius * 1.5, 0, TAU, 64,
			Color(node_color.r, node_color.g, node_color.b, 0.5), 2.0)

	# 1. 일반 선택 범위 (클릭 - 시너지 등 적용된 실시간 범위)
	if is_selected and is_placed:
		var range_val: float = _get_ability_range()
		draw_arc(Vector2.ZERO, range_val, 0, TAU, 128,
			Color(node_color.r, node_color.g, node_color.b, 0.8), 1.5)

	# 2. SHIFT 연결 범위 (_is_first_selected - 400 그라데이션)
	if _is_first_selected and is_placed:
		var rings: int = 40
		for i in range(rings, 0, -1):
			var t: float = float(i) / rings
			var r: float = CONNECT_RANGE * t
			var alpha: float = t * t * 0.025
			var fill_pts: PackedVector2Array = []
			for j in range(64):
				var a: float = (TAU / 64) * j
				fill_pts.append(Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(fill_pts,
				Color(node_color.r, node_color.g, node_color.b, alpha))
		draw_arc(Vector2.ZERO, CONNECT_RANGE, 0, TAU, 128,
			Color(node_color.r, node_color.g, node_color.b, 0.6), 1.0)

	if is_highlighted:
		var pulse: float = abs(sin(_time * 4.0))
		draw_arc(Vector2.ZERO, radius * 1.6, 0, TAU, 64,
			Color(1.0, 1.0, 0.5, pulse * 0.8), 2.5)
		draw_arc(Vector2.ZERO, radius * 1.8, 0, TAU, 64,
			Color(1.0, 1.0, 0.5, pulse * 0.3), 1.5)

	# 쿨다운 게이지: 첫 공격 후, 쿨타임 중일 때만 표시 (_attack_timer > 0)
	if is_placed and _has_attacked_once and _attack_timer > 0:
		var cooldown_ratio: float = _attack_timer / attack_cooldown

		# 쿨다운 배경 링 (어두운)
		draw_arc(Vector2.ZERO, radius + 6.0,
			0, TAU, 64,
			Color(0.1, 0.1, 0.1, 0.5), 3.0)

		# 쿨다운 채워지는 링
		if cooldown_ratio > 0:
			draw_arc(Vector2.ZERO, radius + 6.0,
				-PI / 2,
				-PI / 2 + TAU * cooldown_ratio,
				64,
				Color(node_color.r, node_color.g, node_color.b, 0.85),
				3.0)

		# 쿨다운 완료 시 잠깐 번쩍
		if _attack_timer >= attack_cooldown - 0.1:
			draw_arc(Vector2.ZERO, radius + 6.0,
				0, TAU, 64,
				Color(node_color.r, node_color.g, node_color.b, 0.4),
				5.0)

func _get_ability_range() -> float:
	match node_type:
		"흡혈":
			return 200.0
		"결계":
			return 400.0 if synergy_wide_slow else 200.0
		"증폭":
			return 120.0
	return 200.0

func on_right_click() -> void:
	var cm = get_tree().get_first_node_in_group("connection_manager")

	# 연결 대기 중이면 취소만
	if cm and cm._pending != null:
		return

	if not is_placed:
		return

	# 연결된 상태면 연결 해제만 (노드 유지)
	if cm:
		var conns = cm.get_connections_for(self)
		if conns.size() > 0:
			cm.disconnect_from(self)
			return  # 노드 제거 안함

	# 연결 없는 상태면 노드 제거 + 환불
	var grid = get_tree().get_first_node_in_group("heart_pulse")
	if grid and grid_col >= 0 and grid_row >= 0:
		grid.remove_node(grid_col, grid_row)

	if not is_starter_node:
		var base_cost: float = 0.0
		match node_type:
			"흡혈": base_cost = 10.0
			"결계": base_cost = 15.0
			"증폭": base_cost = 20.0
		if ResourceManager:
			ResourceManager.add_blood(base_cost * 0.5)

	_spawn_burst_effect()
	queue_free()

func _spawn_burst_effect() -> void:
	var effect = Node2D.new()
	effect.set_script(preload("res://scripts/NodeBurstEffect.gd"))
	effect.global_position = global_position
	get_parent().add_child(effect)
	effect.setup(node_color)

func _get_node_info() -> Dictionary:
	match node_type:
		"흡혈":
			return {
				name = "흡혈",
				desc = "가장 가까운 혈체 공격",
				synergy1 = "결계 연결: 데미지 2배",
				synergy2 = "증폭 연결: 쿨다운 50%↓",
				atk = 30,
				cooldown = 2.0
			}
		"결계":
			return {
				name = "결계",
				desc = "혈체 이동 감속",
				synergy1 = "흡혈 연결: 데미지 2배",
				synergy2 = "증폭 연결: 감속 범위 2배",
				atk = 0,
				cooldown = 3.0
			}
		"증폭":
			return {
				name = "증폭",
				desc = "인접 노드 강화",
				synergy1 = "흡혈 연결: 쿨다운 50%↓",
				synergy2 = "결계 연결: 감속 범위 2배",
				atk = 0,
				cooldown = 3.0
			}
	return {name = "", desc = "", synergy1 = "", synergy2 = "", atk = 0, cooldown = 0.0}

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
		var cm = get_tree().get_first_node_in_group("connection_manager")
		if cm and cm.has_method("set_last_placed"):
			cm.set_last_placed(self)
	else:
		_return_to_slot()

func _return_to_slot() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", _slot_position, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _do_attack() -> bool:
	match node_type:
		"흡혈":
			var diff: int = ResourceManager.difficulty if ResourceManager else 0
			var damage: float = 25.0 + diff * 10.0
			return _attack_nearest_entity(damage)
		"결계":
			return _slow_nearest_entity()
		"증폭":
			return _boost_adjacent_nodes()
	return false

func _attack_nearest_entity(damage: float) -> bool:
	var entities = get_tree().get_nodes_in_group("blood_entities")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for e in entities:
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e

	if nearest and nearest_dist <= 200.0:
		_spawn_attack_line(nearest.global_position)
		if nearest.has_method("take_damage"):
			var final_damage: float = damage
			if synergy_double_damage and nearest.has_method("is_slowed") and nearest.is_slowed():
				final_damage *= 2.0
				# 시너지 데미지 적용 시 "SYNERGY!" 팝업
				var label: Label = Label.new()
				label.text = "SYNERGY!"
				label.add_theme_font_size_override("font_size", 18)
				label.add_theme_color_override("font_color",
					Color(1.0, 0.8, 0.2, 1.0))
				label.global_position = global_position + Vector2(-40, -50)
				get_parent().add_child(label)
				var tween: Tween = label.create_tween()
				tween.tween_property(label, "global_position",
					label.global_position + Vector2(0, -30), 0.6)
				tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
				tween.tween_callback(label.queue_free)
			nearest.take_damage(final_damage)
		return true
	return false

func _slow_nearest_entity() -> bool:
	var slow_range: float = 200.0
	var slow_duration: float = 3.0
	if synergy_wide_slow:
		slow_range *= 2.0
		slow_duration *= 2.0

	var hit_any: bool = false
	var entities = get_tree().get_nodes_in_group("blood_entities")
	for e in entities:
		if global_position.distance_to(e.global_position) <= slow_range:
			if e.has_method("apply_slow"):
				_spawn_attack_line(e.global_position)
				e.apply_slow(0.5, slow_duration)
				hit_any = true
	return hit_any

func _boost_adjacent_nodes() -> bool:
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	var boosted_any: bool = false
	for n in nodes:
		if n == self:
			continue
		var d: float = global_position.distance_to(n.global_position)
		if d < 120.0:
			n.attack_cooldown = attack_cooldown * 0.7
			boosted_any = true
	return boosted_any

func _spawn_attack_line(target_pos: Vector2) -> void:
	var line = Node2D.new()
	line.set_script(preload("res://scripts/AttackLine.gd"))
	line.global_position = Vector2.ZERO
	get_parent().add_child(line)
	line._from = global_position
	line._to = target_pos
	line._color = node_color
