extends Node2D

@onready var blood_entity_scene = preload("res://scenes/BloodEntity.tscn")
@onready var _coffin_rect: ColorRect = $CanvasLayer/Coffin
@onready var _vignette: ColorRect = $CanvasLayer/VignetteOverlay
@onready var _live_dot: Label = $CanvasLayer/TopBar/LiveDot
@onready var _blood_label: Label = $CanvasLayer/TopBar/BloodLabel
@onready var _tooltip: ColorRect = $CanvasLayer/TooltipBar
@onready var _tip_name: Label = $CanvasLayer/TooltipBar/NodeName
@onready var _tip_desc: Label = $CanvasLayer/TooltipBar/NodeDesc
@onready var _tip_syn1: Label = $CanvasLayer/TooltipBar/Synergy1
@onready var _tip_syn2: Label = $CanvasLayer/TooltipBar/Synergy2
@onready var _stat_atk: Label = $CanvasLayer/TooltipBar/StatATK
@onready var _stat_cd: Label = $CanvasLayer/TooltipBar/StatCooldown
@onready var _hint_popup: PanelContainer = $CanvasLayer/HintPopup
@onready var _hint_label: Label = $CanvasLayer/HintPopup/HintLabel
@onready var _hint_area: Control = $CanvasLayer/HintArea
@onready var _dots_container: Control = $CanvasLayer/HintArea/DotsContainer
var _left_tween: Tween
var _right_tween: Tween
var _hp_tween: Tween
var _damage_tween: Tween
var _left_open: bool = false
var _right_open: bool = false
var spawn_timer: float = 0.0
var spawn_interval: float = 3.0
var max_entities: int = 5
var coffin_hp: float = 100.0
var coffin_max_hp: float = 100.0
var _hp_hide_timer: float = 0.0
var _hp_visible: bool = false
var _blink_timer: float = 0.0
var _blink_state: bool = true
var _is_game_over: bool = false
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _vignette_tween: Tween
var _node_slots: Array = [
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "cost": 10},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "cost": 15},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "cost": 20},
]
var _hint_hiding: bool = false
var _elapsed_time: float = 0.0

func _ready() -> void:
	add_to_group("main")
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Main 시작")
	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2
	$EntityLayer/HeartPulse.setup(coffin_center)
	var coffin_particles: Node2D = Node2D.new()
	coffin_particles.set_script(preload("res://scripts/CoffinParticles.gd"))
	coffin_particles.setup(coffin_center)
	$EntityLayer.add_child(coffin_particles)
	$CanvasLayer/LeftPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/RightPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/LeftPanel.position = Vector2(-220, $CanvasLayer/LeftPanel.position.y)
	$CanvasLayer/RightPanel.position = Vector2(1920, $CanvasLayer/RightPanel.position.y)
	$CanvasLayer/LeftTab.gui_input.connect(_on_left_tab_gui_input)
	$CanvasLayer/RightTab.gui_input.connect(_on_right_tab_gui_input)
	$CanvasLayer/CoffinHPBar.modulate = Color(1, 1, 1, 0)
	_hint_popup.visible = false
	_spawn_start_nodes()
	var synergy_engine = SynergyEngine.new()
	add_child(synergy_engine)
	_build_hint_dots()
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/SpecialRow.modulate = Color(1, 1, 1, 0.5)
	ResourceManager.blood_changed.connect(_on_blood_changed)
	ResourceManager.blood_changed.connect(update_blood_ui)
	ResourceManager.special_changed.connect(_on_special_changed)
	_on_blood_changed(ResourceManager.blood)
	update_blood_ui(ResourceManager.blood)
	_on_special_changed(ResourceManager.special)

func show_tooltip(info: Dictionary, node_color: Color) -> void:
	_tip_name.text = info.name
	_tip_desc.text = info.desc
	_tip_syn1.text = "◆ " + info.synergy1
	_tip_syn2.text = "◆ " + info.synergy2
	_stat_atk.text = "⚔ 공격력: " + str(info.atk)
	_stat_cd.text = "⏱ 쿨다운: " + str(info.cooldown) + "s"
	_tip_syn1.add_theme_color_override("font_color", node_color.lightened(0.3))
	_tip_syn2.add_theme_color_override("font_color", node_color.lightened(0.3))
	_tooltip.visible = true

func hide_tooltip() -> void:
	_tooltip.visible = false

func _spawn_start_nodes() -> void:
	var node_scene = preload("res://scenes/GameNode.tscn")
	var grid = $EntityLayer/HeartPulse

	var start_nodes = [
		{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1)},
		{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9)},
	]

	for i in range(start_nodes.size()):
		var data = start_nodes[i]
		var node = node_scene.instantiate()
		node.node_id = data.id
		node.node_type = data.type
		node.node_color = data.color
		# 관 좌우에 배치
		var offset_x: float = -120.0 if i == 0 else 120.0
		var pos: Vector2 = Vector2(960 + offset_x, 600)
		node.global_position = pos
		node._slot_position = pos
		# 그리드에 등록 + is_placed 설정 (SHIFT 시너지 연결 가능)
		var cell: Vector2i = grid.world_to_grid(pos)
		if grid.is_valid_cell(cell.x, cell.y) and grid.is_cell_empty(cell.x, cell.y):
			grid.place_node(cell.x, cell.y, node.node_id)
			node.is_placed = true
			node.grid_col = cell.x
			node.grid_row = cell.y
		$EntityLayer.add_child(node)

func _build_hint_dots() -> void:
	var slot_size: int = 70
	var spacing: int = 100
	var total_width: int = _node_slots.size() * spacing
	var start_x: int = (1920 - total_width) / 2

	for i in range(_node_slots.size()):
		var data = _node_slots[i]

		var slot: Button = Button.new()
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.size = Vector2(slot_size, slot_size)
		slot.position = Vector2(start_x + i * spacing, 15)

		# 노드 타입 이름
		slot.text = data.type + "\n🩸" + str(data.cost)
		slot.add_theme_font_size_override("font_size", 12)
		slot.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))

		# 슬롯 스타일
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(
			data.color.r * 0.25,
			data.color.g * 0.25,
			data.color.b * 0.25, 0.92)
		style.set_corner_radius_all(35)
		style.border_color = Color(
			data.color.r, data.color.g, data.color.b, 0.7)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		slot.add_theme_stylebox_override("normal", style)

		# 호버 스타일
		var hover: StyleBoxFlat = StyleBoxFlat.new()
		hover.bg_color = Color(
			data.color.r * 0.5,
			data.color.g * 0.5,
			data.color.b * 0.5, 1.0)
		hover.set_corner_radius_all(35)
		hover.border_color = Color(
			data.color.r, data.color.g, data.color.b, 1.0)
		hover.border_width_left = 2
		hover.border_width_right = 2
		hover.border_width_top = 2
		hover.border_width_bottom = 2
		slot.add_theme_stylebox_override("hover", hover)

		slot.modulate.a = 0.0
		slot.pressed.connect(func(): _spawn_node_from_slot(i))
		_dots_container.add_child(slot)

func _spawn_node_from_slot(index: int) -> void:
	var data = _node_slots[index]

	# 재화 확인
	if ResourceManager.blood < data.cost:
		# 재화 부족 - 슬롯 흔들기
		var slot = _dots_container.get_child(index)
		var tween: Tween = create_tween()
		tween.tween_property(slot, "position:x",
			slot.position.x + 8, 0.05)
		tween.tween_property(slot, "position:x",
			slot.position.x - 8, 0.05)
		tween.tween_property(slot, "position:x",
			slot.position.x, 0.05)
		return

	# 재화 차감
	ResourceManager.spend_blood(data.cost)

	# 노드 스폰 (클릭한 인디케이터 슬롯 위에 배치 → 바로 드래그 가능)
	var slot: Control = _dots_container.get_child(index)
	var slot_center: Vector2 = slot.global_position + slot.size / 2
	# 슬롯 바로 위에 생성 (인디케이터 영역에서 드래그 시작 가능)
	var spawn_pos: Vector2 = slot_center + Vector2(0, -70)

	var node_scene = preload("res://scenes/GameNode.tscn")
	var node = node_scene.instantiate()
	node.node_id = data.id
	node.node_type = data.type
	node.node_color = data.color
	node.global_position = spawn_pos
	node._slot_position = spawn_pos
	$EntityLayer.add_child(node)

func _get_hovered_game_node():
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.is_hovered:
			return n
	return null

func _process(delta: float) -> void:
	if _is_game_over:
		_apply_shake(delta)
		return
	_elapsed_time += delta

	# 난이도 단계 (30초마다)
	var difficulty: int = int(_elapsed_time / 30.0)
	spawn_interval = max(1.5, 4.0 - difficulty * 0.35)
	max_entities = min(10, 4 + difficulty)
	if ResourceManager:
		ResourceManager.difficulty = difficulty

	_blink_timer += delta
	if _blink_timer >= 0.8:
		_blink_timer = 0.0
		_blink_state = !_blink_state
		_live_dot.modulate.a = 1.0 if _blink_state else 0.2
	if coffin_hp >= 45:
		_live_dot.add_theme_color_override("font_color", Color(0, 1, 0.267, 1))
	elif coffin_hp >= 13:
		_live_dot.add_theme_color_override("font_color", Color(1, 1, 0, 1))
	else:
		_live_dot.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if get_tree().get_nodes_in_group("blood_entities").size() < max_entities:
			_spawn_blood_entity()

	_check_coffin_collision()

	if _hp_visible:
		_hp_hide_timer -= delta
		if _hp_hide_timer <= 0.0:
			_hp_visible = false
			_fade_hp_bar(false)

	var my: float = get_viewport().get_mouse_position().y
	if my > 820:
		_hint_hiding = false
		if not _hint_area.visible:
			_hint_area.visible = true
			_hint_area.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 1020.0)

			var area_tween: Tween = _hint_area.create_tween()
			area_tween.tween_property(_hint_area, "position:y", 950.0, 0.35
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				dot.position = Vector2(dot.position.x, 70.0)
				dot.modulate = Color(1, 1, 1, 0)

				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.07)
				tween.tween_property(dot, "position:y", 30.0, 0.35
				).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.25)
	else:
		if _hint_area.visible and not _hint_hiding:
			_hint_hiding = true
			var area_tween: Tween = _hint_area.create_tween()
			area_tween.tween_property(_hint_area, "position:y", 1020.0, 0.25
			).set_ease(Tween.EASE_IN)

			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.05)
				tween.tween_property(dot, "position:y", 70.0, 0.25
				).set_ease(Tween.EASE_IN)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 0), 0.2)

			var hide_delay: float = dots.size() * 0.05 + 0.25
			get_tree().create_timer(hide_delay).timeout.connect(func():
				if _hint_hiding:
					_hint_area.visible = false
					_hint_hiding = false
			)

	var hovered_node = _get_hovered_game_node()
	if hovered_node:
		show_tooltip(hovered_node._get_node_info(), hovered_node.node_color)
	else:
		hide_tooltip()

	_apply_shake(delta)

func _spawn_blood_entity() -> void:
	var difficulty: int = int(_elapsed_time / 30.0)
	var entity
	if difficulty >= 4:
		entity = preload("res://scenes/BloodEntityStage4.tscn").instantiate()
	else:
		entity = blood_entity_scene.instantiate()

	entity.add_to_group("blood_entities")

	entity.max_hp = 60.0 + difficulty * 20.0
	entity.hp = entity.max_hp
	entity.speed = 45.0 + difficulty * 7.0
	entity.radius = 27.0 + difficulty * 2.0
	if entity.has_method("_generate_points"):
		entity._generate_points()
	elif entity.has_method("_generate_tendrils"):
		entity._generate_tendrils()

	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2

	var side: int = randi() % 4
	var pos: Vector2
	match side:
		0: pos = Vector2(randf_range(0, 1920), -50)
		1: pos = Vector2(randf_range(0, 1920), 1130)
		2: pos = Vector2(-50, randf_range(0, 1080))
		3: pos = Vector2(1970, randf_range(0, 1080))

	entity.global_position = pos
	entity.target = coffin_center
	$EntityLayer.add_child(entity)

func _check_coffin_collision() -> void:
	var coffin_rect: Rect2 = Rect2(_coffin_rect.global_position, _coffin_rect.size)
	for entity in get_tree().get_nodes_in_group("blood_entities"):
		if coffin_rect.has_point(entity.global_position):
			entity.remove_from_group("blood_entities")
			entity.queue_free()
			coffin_hp -= 10.0
			coffin_hp = max(coffin_hp, 0.0)
			_trigger_shake()
			_trigger_vignette()
			_trigger_shockwave(entity.global_position)
			_show_hp_bar()
			if coffin_hp <= 0.0:
				_game_over()

func _show_hp_bar() -> void:
	var hp_fill = $CanvasLayer/CoffinHPBar/HPFill
	var damage_bar = $CanvasLayer/CoffinHPBar/DamageBar
	var label = $CanvasLayer/CoffinHPBar/HPBarLabel

	damage_bar.modulate = Color(1, 1, 1, 1)

	var ratio: float = coffin_hp / coffin_max_hp
	var damage_ratio: float = (coffin_hp + 10.0) / coffin_max_hp

	hp_fill.offset_right = 1200.0 * ratio

	damage_bar.offset_right = 1200.0 * damage_ratio
	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_property(
		damage_bar, "offset_right", 1200.0 * ratio, 0.6
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

	label.text = "HP %d / %d" % [int(coffin_hp), int(coffin_max_hp)]

	_fade_hp_bar(true)
	_hp_visible = true
	_hp_hide_timer = 1.0

func _apply_shake(delta: float) -> void:
	if _shake_duration > 0:
		_shake_duration -= delta
		$EntityLayer.position = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		$EntityLayer.position = Vector2.ZERO

func _trigger_shake() -> void:
	var hp_ratio: float = coffin_hp / coffin_max_hp
	_shake_intensity = lerp(4.0, 12.0, 1.0 - hp_ratio)
	_shake_duration = 0.3

func _trigger_vignette() -> void:
	if _vignette_tween:
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(_vignette, "modulate", Color(1, 1, 1, 0.7), 0.05).set_ease(Tween.EASE_OUT)
	_vignette_tween.tween_property(_vignette, "modulate", Color(1, 1, 1, 0), 0.4).set_ease(Tween.EASE_IN)

func _trigger_shockwave(hit_pos: Vector2) -> void:
	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2

	for i in range(12):
		var shard: Node2D = Node2D.new()
		shard.set_script(preload("res://scripts/ShockwaveShardEffect.gd"))
		var base_angle: float = (hit_pos - coffin_center).angle()
		var spread: float = randf_range(-PI * 0.25, PI * 0.25)
		var angle: float = base_angle + spread
		var speed: float = randf_range(500.0, 850.0)
		var size: float = randf_range(4.0, 12.0)
		shard.set("_vel", Vector2(cos(angle), sin(angle)) * speed)
		shard.set("_size", size)
		shard.set("_origin", hit_pos)
		shard.set("_spread_sign", 1.0 if spread >= 0 else -1.0)
		$EntityLayer.add_child(shard)
		shard.global_position = hit_pos

	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 0.3, 0.3, 0.5)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.set_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(flash)
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color", Color(1.0, 0.3, 0.3, 0.0), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _fade_hp_bar(show: bool) -> void:
	if _hp_tween:
		_hp_tween.kill()
	if not show:
		$CanvasLayer/CoffinHPBar/DamageBar.modulate = Color(1, 1, 1, 0)
	_hp_tween = create_tween()
	var target_alpha: float = 0.85 if show else 0.0
	_hp_tween.tween_property(
		$CanvasLayer/CoffinHPBar, "modulate", Color(1, 1, 1, target_alpha), 0.3
	).set_ease(Tween.EASE_OUT)

func _game_over() -> void:
	_is_game_over = true
	_live_dot.modulate.a = 1.0
	_live_dot.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0, 1.0))
	get_tree().paused = true

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.05, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$CanvasLayer.add_child(overlay)

	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.05, 0.0, 0.0, 0.85), 1.0).set_ease(Tween.EASE_OUT)

	await tween.finished

	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 col = textureLod(screen_texture, SCREEN_UV, 0.0);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(col.rgb, vec3(gray), amount), col.a);
}
"""
	shader_mat.shader = shader

	var bw_overlay: ColorRect = ColorRect.new()
	bw_overlay.color = Color(1, 1, 1, 1)
	bw_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bw_overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	bw_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bw_overlay.material = shader_mat
	$CanvasLayer.add_child(bw_overlay)

	var tween_bw: Tween = create_tween()
	tween_bw.tween_method(
		func(v: float): shader_mat.set_shader_parameter("amount", v),
		0.0, 1.0, 1.5
	).set_ease(Tween.EASE_OUT)

	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2

	var label1: Label = Label.new()
	label1.text = "...아직은 아니야"
	label1.add_theme_font_size_override("font_size", 36)
	label1.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.0))
	label1.position = coffin_center + Vector2(-120, -80)
	$CanvasLayer.add_child(label1)

	var tween2: Tween = create_tween()
	tween2.tween_property(label1, "theme_override_colors/font_color", Color(0.8, 0.8, 0.8, 1.0), 0.8)
	await tween2.finished
	await get_tree().create_timer(1.2).timeout

	var label2: Label = Label.new()
	label2.text = "GAME OVER"
	label2.add_theme_font_size_override("font_size", 72)
	label2.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1, 0.0))
	label2.position = coffin_center + Vector2(-240, -30)
	$CanvasLayer.add_child(label2)

	var tween3: Tween = create_tween()
	tween3.tween_property(label2, "theme_override_colors/font_color", Color(1.0, 0.1, 0.1, 1.0), 0.6)
	await tween3.finished
	await get_tree().create_timer(1.5).timeout

	var label3: Label = Label.new()
	label3.text = "[ R ] 재시작"
	label3.add_theme_font_size_override("font_size", 20)
	label3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	label3.position = coffin_center + Vector2(-60, 60)
	$CanvasLayer.add_child(label3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if _left_open:
				_slide_left_close()
			else:
				_slide_left_open()
			_left_open = !_left_open

		if event.keycode == KEY_E:
			if _right_open:
				_slide_right_close()
			else:
				_slide_right_open()
			_right_open = !_right_open

		if event.keycode == KEY_R and _is_game_over:
			get_tree().paused = false
			get_tree().reload_current_scene()

func _on_left_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_left_tab_clicked()

func _on_right_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_right_tab_clicked()

func _on_left_tab_clicked() -> void:
	if _left_open:
		_slide_left_close()
	else:
		_slide_left_open()
	_left_open = !_left_open

func _on_right_tab_clicked() -> void:
	if _right_open:
		_slide_right_close()
	else:
		_slide_right_open()
	_right_open = !_right_open

func _slide_left_open() -> void:
	if _left_tween:
		_left_tween.kill()
	_left_tween = create_tween()
	_left_tween.set_parallel(true)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "position", Vector2(40, $CanvasLayer/LeftPanel.position.y), 0.25
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 1), 0.25
	).set_ease(Tween.EASE_OUT)

func _slide_left_close() -> void:
	if _left_tween:
		_left_tween.kill()
	_left_tween = create_tween()
	_left_tween.set_parallel(true)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "position", Vector2(-220, $CanvasLayer/LeftPanel.position.y), 0.25
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property(
		$CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 0), 0.25
	).set_ease(Tween.EASE_IN)

func _slide_right_open() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "position", Vector2(1640, $CanvasLayer/RightPanel.position.y), 0.25
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 1), 0.25
	).set_ease(Tween.EASE_OUT)

func _on_blood_changed(new_value: int) -> void:
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow/BloodValue.text = "%d" % new_value

func _on_special_changed(new_value: float) -> void:
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/SpecialRow/SpecialValue.text = "%d" % int(new_value)
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/SpecialRow
	row.modulate = Color(1, 1, 1, 0.5 if new_value <= 0 else 1.0)

func update_blood_ui(amount: float) -> void:
	# TopBar에 혈액 재화 표시
	_blood_label.text = "🩸 " + str(int(amount))


func _slide_right_close() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "position", Vector2(1920, $CanvasLayer/RightPanel.position.y), 0.25
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property(
		$CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 0), 0.25
	).set_ease(Tween.EASE_IN)
