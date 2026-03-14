# VELMIRE 프로젝트 전체 스냅샷

생성일: 2025-03-13

---

## 1. 모든 .gd 파일 전체 코드

### scripts/Main.gd

```gdscript
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
		var offset_x: float = -120.0 if i == 0 else 120.0
		var pos: Vector2 = Vector2(960 + offset_x, 600)
		node.global_position = pos
		node._slot_position = pos
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
		slot.text = data.type + "\n🩸" + str(data.cost)
		slot.add_theme_font_size_override("font_size", 12)
		slot.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(data.color.r * 0.25, data.color.g * 0.25, data.color.b * 0.25, 0.92)
		style.set_corner_radius_all(35)
		style.border_color = Color(data.color.r, data.color.g, data.color.b, 0.7)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		slot.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = StyleBoxFlat.new()
		hover.bg_color = Color(data.color.r * 0.5, data.color.g * 0.5, data.color.b * 0.5, 1.0)
		hover.set_corner_radius_all(35)
		hover.border_color = Color(data.color.r, data.color.g, data.color.b, 1.0)
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
	if ResourceManager.blood < data.cost:
		var slot = _dots_container.get_child(index)
		var tween: Tween = create_tween()
		tween.tween_property(slot, "position:x", slot.position.x + 8, 0.05)
		tween.tween_property(slot, "position:x", slot.position.x - 8, 0.05)
		tween.tween_property(slot, "position:x", slot.position.x, 0.05)
		return
	ResourceManager.spend_blood(data.cost)
	var node_scene = preload("res://scenes/GameNode.tscn")
	var node = node_scene.instantiate()
	node.node_id = data.id
	node.node_type = data.type
	node.node_color = data.color
	node.global_position = Vector2(960, 500)
	node._slot_position = Vector2(960, 500)
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
			area_tween.tween_property(_hint_area, "position:y", 950.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				dot.position = Vector2(dot.position.x, 70.0)
				dot.modulate = Color(1, 1, 1, 0)
				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.07)
				tween.tween_property(dot, "position:y", 30.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.25)
	else:
		if _hint_area.visible and not _hint_hiding:
			_hint_hiding = true
			var area_tween: Tween = _hint_area.create_tween()
			area_tween.tween_property(_hint_area, "position:y", 1020.0, 0.25).set_ease(Tween.EASE_IN)
			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.05)
				tween.tween_property(dot, "position:y", 70.0, 0.25).set_ease(Tween.EASE_IN)
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
	var entity = blood_entity_scene.instantiate()
	entity.add_to_group("blood_entities")
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
	_damage_tween.tween_property(damage_bar, "offset_right", 1200.0 * ratio, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	label.text = "HP %d / %d" % [int(coffin_hp), int(coffin_max_hp)]
	_fade_hp_bar(true)
	_hp_visible = true
	_hp_hide_timer = 1.0

func _apply_shake(delta: float) -> void:
	if _shake_duration > 0:
		_shake_duration -= delta
		$EntityLayer.position = Vector2(randf_range(-_shake_intensity, _shake_intensity), randf_range(-_shake_intensity, _shake_intensity))
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
	_hp_tween.tween_property($CanvasLayer/CoffinHPBar, "modulate", Color(1, 1, 1, target_alpha), 0.3).set_ease(Tween.EASE_OUT)

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
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest; uniform float amount : hint_range(0.0, 1.0) = 0.0; void fragment() { vec4 col = textureLod(screen_texture, SCREEN_UV, 0.0); float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114)); COLOR = vec4(mix(col.rgb, vec3(gray), amount), col.a); }"
	shader_mat.shader = shader
	var bw_overlay: ColorRect = ColorRect.new()
	bw_overlay.color = Color(1, 1, 1, 1)
	bw_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bw_overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	bw_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bw_overlay.material = shader_mat
	$CanvasLayer.add_child(bw_overlay)
	var tween_bw: Tween = create_tween()
	tween_bw.tween_method(func(v: float): shader_mat.set_shader_parameter("amount", v), 0.0, 1.0, 1.5).set_ease(Tween.EASE_OUT)
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
	_left_tween.tween_property($CanvasLayer/LeftPanel, "position", Vector2(40, $CanvasLayer/LeftPanel.position.y), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property($CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT)

func _slide_left_close() -> void:
	if _left_tween:
		_left_tween.kill()
	_left_tween = create_tween()
	_left_tween.set_parallel(true)
	_left_tween.tween_property($CanvasLayer/LeftPanel, "position", Vector2(-220, $CanvasLayer/LeftPanel.position.y), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_left_tween.tween_property($CanvasLayer/LeftPanel, "modulate", Color(1, 1, 1, 0), 0.25).set_ease(Tween.EASE_IN)

func _slide_right_open() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property($CanvasLayer/RightPanel, "position", Vector2(1640, $CanvasLayer/RightPanel.position.y), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property($CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT)

func _slide_right_close() -> void:
	if _right_tween:
		_right_tween.kill()
	_right_tween = create_tween()
	_right_tween.set_parallel(true)
	_right_tween.tween_property($CanvasLayer/RightPanel, "position", Vector2(1920, $CanvasLayer/RightPanel.position.y), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	_right_tween.tween_property($CanvasLayer/RightPanel, "modulate", Color(1, 1, 1, 0), 0.25).set_ease(Tween.EASE_IN)

func _on_blood_changed(new_value: int) -> void:
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow/BloodValue.text = "%d" % new_value

func _on_special_changed(new_value: float) -> void:
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/SpecialRow/SpecialValue.text = "%d" % int(new_value)
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/SpecialRow
	row.modulate = Color(1, 1, 1, 0.5 if new_value <= 0 else 1.0)

func update_blood_ui(amount: float) -> void:
	_blood_label.text = "🩸 " + str(int(amount))
```

---

### scripts/ResourceManager.gd

```gdscript
extends Node

signal resource_changed(type: String, new_value: Variant)
signal blood_changed(new_value: int)
signal special_changed(new_value: float)

var blood: int = 0
var special: float = 0.0
var node_fragments: int = 0


func _ready() -> void:
	print("ResourceManager 시작")
	pass


## SynergyEngine에서 시너지 발동 시 호출됨
func apply_synergy_effect(synergy: Dictionary, effect_data: Dictionary, position: Vector2) -> void:
	pass


func add_blood(amount) -> void:
	blood += int(amount)
	blood_changed.emit(blood)


func add_special(amount: float) -> void:
	special += amount
	special_changed.emit(special)


func add_resource(type: String, amount: float) -> void:
	match type:
		"blood":
			blood += int(amount)
			resource_changed.emit("blood", blood)
			blood_changed.emit(blood)
		"special":
			special += amount
			resource_changed.emit("special", special)
			special_changed.emit(special)
		"node":
			node_fragments += int(amount)
			resource_changed.emit("node", node_fragments)


func spend_blood(amount: float) -> bool:
	var amt: int = int(amount)
	if blood < amt:
		return false
	blood -= amt
	resource_changed.emit("blood", blood)
	blood_changed.emit(blood)
	return true


func spend_special(amount: float) -> bool:
	if special < amount:
		return false
	special -= amount
	special_changed.emit("special", special)
	return true


func get_all() -> Dictionary:
	return {
		"blood": blood,
		"special": special,
		"node": node_fragments
	}
```

---

### scripts/BloodEntityAI.gd

```gdscript
extends Node2D

var speed: float = 90.0
var hp: float = 100.0
var max_hp: float = 100.0
var damage: float = 10.0
var target: Vector2 = Vector2(960, 540)
var _rotation_speed: float = 0.0
var _points: PackedVector2Array = []
var _is_slowed: bool = false
var _base_radius: float = 35.0
var _hp_bar_alpha: float = 0.0
var _hp_bar_timer: float = 0.0
var _hp_bar_duration: float = 2.0
var _damage_bar_ratio: float = 1.0

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_generate_points()

func _generate_points() -> void:
	var num: int = randi_range(6, 9)
	_base_radius = randf_range(27.0, 42.0)
	_points.clear()
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = _base_radius + randf_range(-8.0, 8.0)
		_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _get_smooth_points() -> PackedVector2Array:
	var smooth: PackedVector2Array = []
	var count: int = _points.size()
	for i in range(count):
		var curr: Vector2 = _points[i]
		var next: Vector2 = _points[(i + 1) % count]
		var prev: Vector2 = _points[(i - 1 + count) % count]
		smooth.append(curr.lerp(prev, 0.16))
		smooth.append(curr.lerp((prev + next) / 2.0, 0.08))
		smooth.append(curr.lerp(next, 0.16))
	return smooth

func _process(delta: float) -> void:
	rotation += _rotation_speed * delta
	var dir: Vector2 = (target - global_position).normalized()
	global_position += dir * speed * delta
	if _hp_bar_timer > 0:
		_hp_bar_timer -= delta
		if _hp_bar_timer <= 0.5:
			_hp_bar_alpha = _hp_bar_timer / 0.5
	else:
		_hp_bar_alpha = 0.0
	queue_redraw()

func _draw() -> void:
	if _points.size() == 0:
		return
	var smooth: PackedVector2Array = _get_smooth_points()
	draw_colored_polygon(smooth, Color(0.35, 0.0, 0.0, 1.0))
	for i in range(smooth.size()):
		var a: Vector2 = smooth[i]
		var b: Vector2 = smooth[(i + 1) % smooth.size()]
		draw_line(a, b, Color(0.6, 0.05, 0.05, 1.0), 1.5)
	if _hp_bar_alpha > 0:
		var angle: float = -rotation
		var bar_w: float = 40.0
		var bar_h: float = 5.0
		var bar_offset: Vector2 = Vector2(0, -38).rotated(angle)
		var bar_x: Vector2 = Vector2(cos(angle), sin(angle))
		var bar_y: Vector2 = Vector2(-sin(angle), cos(angle))
		var tl: Vector2 = bar_offset + bar_x * (-bar_w / 2) + bar_y * (-bar_h / 2)
		var tr: Vector2 = bar_offset + bar_x * (bar_w / 2) + bar_y * (-bar_h / 2)
		var br: Vector2 = bar_offset + bar_x * (bar_w / 2) + bar_y * (bar_h / 2)
		var bl: Vector2 = bar_offset + bar_x * (-bar_w / 2) + bar_y * (bar_h / 2)
		draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]), Color(0.15, 0.0, 0.0, _hp_bar_alpha * 0.9))
		var tr_d: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * _damage_bar_ratio) + bar_y * (-bar_h / 2)
		var br_d: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * _damage_bar_ratio) + bar_y * (bar_h / 2)
		draw_colored_polygon(PackedVector2Array([tl, tr_d, br_d, bl]), Color(0.7, 0.7, 0.7, _hp_bar_alpha * 0.8))
		var hp_ratio: float = hp / max_hp
		var tr_h: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * hp_ratio) + bar_y * (-bar_h / 2)
		var br_h: Vector2 = bar_offset + bar_x * (-bar_w / 2 + bar_w * hp_ratio) + bar_y * (bar_h / 2)
		draw_colored_polygon(PackedVector2Array([tl, tr_h, br_h, bl]), Color(1.0, 0.15, 0.15, _hp_bar_alpha))

func take_damage(amount: float) -> void:
	hp -= amount
	_spawn_damage_number(amount)
	if hp <= 0:
		_spawn_death_effect()
		_drop_blood()
		remove_from_group("blood_entities")
		queue_free()

func _spawn_death_effect() -> void:
	var effect = Node2D.new()
	effect.set_script(preload("res://scripts/DeathEffect.gd"))
	effect.global_position = global_position
	get_parent().add_child(effect)

func _drop_blood() -> void:
	var drop_scene = preload("res://scenes/BloodDrop.tscn")
	var drop_count: int = 3
	var coffin_center = get_tree().get_first_node_in_group("coffin")
	if not coffin_center:
		return
	var target: Vector2 = coffin_center.global_position + coffin_center.size / 2
	for i in range(drop_count):
		var drop = drop_scene.instantiate()
		get_parent().add_child(drop)
		drop.setup(global_position, 1.0, target)

func _spawn_damage_number(amount: float) -> void:
	var label: Label = Label.new()
	label.text = str(int(amount))
	label.add_theme_font_size_override("font_size", 18)
	if amount > 30:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		label.add_theme_font_size_override("font_size", 24)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	label.global_position = global_position + Vector2(randf_range(-10, 10), -40)
	get_parent().add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -40), 0.8)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(label.queue_free)

func is_slowed() -> bool:
	return _is_slowed

func apply_slow(factor: float, duration: float) -> void:
	_is_slowed = true
	speed *= factor
	await get_tree().create_timer(duration).timeout
	if is_inside_tree():
		speed /= factor
	_is_slowed = false
```

*(전체 147줄 - 생략된 본문은 아래 "주요 함수 목록" 참고)*

---

### scripts/BloodDrop.gd

```gdscript
extends Node2D

var value: float = 1.0
var _target: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _time: float = 0.0
var _size: float = 6.0
var _alpha: float = 1.0
var _phase: String = "burst"
var _burst_vel: Vector2 = Vector2.ZERO
var _curve_angle: float = 0.0

func setup(pos: Vector2, drop_value: float, coffin_center: Vector2) -> void:
	global_position = pos
	value = drop_value
	_target = coffin_center
	_size = clamp(drop_value * 2.0, 4.0, 16.0)
	var away_dir: Vector2 = (pos - coffin_center).normalized()
	var spread: float = randf_range(-0.6, 0.6)
	var burst_dir: Vector2 = away_dir.rotated(spread)
	_burst_vel = burst_dir * randf_range(500.0, 900.0)
	_curve_angle = 1.0 if randf() > 0.5 else -1.0

func _process(delta: float) -> void:
	_time += delta
	match _phase:
		"burst":
			_burst_vel *= 0.85
			global_position += _burst_vel * delta
			if _time > 0.4:
				_phase = "suck"
				_speed = 0.0
		"suck":
			var dist: float = global_position.distance_to(_target)
			var dir: Vector2 = (_target - global_position).normalized()
			_speed += 3000.0 * delta
			global_position += dir * _speed * delta
			_size = clamp(dist / 60.0, 0.5, _size)
			if dist < 8.0:
				ResourceManager.add_blood(value)
				queue_free()
	queue_redraw()

func _draw() -> void:
	var pulse: float = sin(_time * 3.0) * 0.8
	var r: float = (_size + pulse) * 0.7
	draw_circle(Vector2.ZERO, r, Color(0.8, 0.0, 0.0, _alpha))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 0.2, 0.2, _alpha * 0.8))
```

---

### scripts/GameNode.gd

```gdscript
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
var attack_cooldown: float = 3.0
var _attack_timer: float = 0.0
var synergy_double_damage: bool = false
var synergy_fast_cooldown: bool = false
var synergy_wide_slow: bool = false
var is_pending_connection: bool = false
var _phase_offset: float = 0.0
var is_hovered: bool = false

func _ready() -> void:
	_generate_base_points()
	_phase_offset = randf_range(0.0, TAU)
	add_to_group("game_nodes")

func _generate_base_points() -> void:
	_base_points.clear()
	var num: int = 32
	for i in range(num):
		var angle: float = (2.0 * PI / num) * i
		var r: float = radius
		_base_points.append(Vector2(cos(angle) * r, sin(angle) * r))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = to_local(get_global_mouse_position())
		var is_hover: bool = local_pos.length() <= radius + 10.0
		if event.pressed and is_hover:
			if Input.is_key_pressed(KEY_SHIFT) and is_placed:
				var cm = get_tree().get_first_node_in_group("connection_manager")
				if cm:
					cm.try_connect(self)
				get_viewport().set_input_as_handled()
			else:
				if is_placed:
					var cm = get_tree().get_first_node_in_group("connection_manager")
					if cm:
						cm.disconnect_node(self)
					var grid = get_tree().get_first_node_in_group("heart_pulse")
					if grid and grid_col >= 0 and grid_row >= 0:
						grid.remove_node(grid_col, grid_row)
					grid_col = -1
					grid_row = -1
				is_placed = false
				is_dragging = true
				_drag_offset = global_position - get_global_mouse_position()
				_slot_position = global_position
				get_viewport().set_input_as_handled()
		elif not event.pressed and is_dragging:
			is_dragging = false
			_try_place_on_grid()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_time += delta
	if is_dragging:
		global_position = get_global_mouse_position() + _drag_offset
	if is_placed:
		_attack_timer += delta
		if _attack_timer >= attack_cooldown:
			_attack_timer = 0.0
			_do_attack()
	var mouse_dist: float = to_local(get_global_mouse_position()).length()
	is_hovered = mouse_dist <= radius + 10.0
	queue_redraw()

func _draw() -> void:
	var pts: PackedVector2Array = []
	for i in range(_base_points.size()):
		var base: Vector2 = _base_points[i]
		var wave: float = sin(_time * 0.7 + i * 0.5 + _phase_offset) * 1.8 + sin(_time * 1.1 + i * 0.8 + _phase_offset * 1.3) * 0.6
		pts.append(base + base.normalized() * wave)
	for g in range(4):
		var scale: float = 1.6 - g * 0.2
		var alpha: float = 0.06 - g * 0.01
		var glow_pts: PackedVector2Array = []
		for p in pts:
			glow_pts.append(p * scale)
		draw_colored_polygon(glow_pts, Color(node_color.r, node_color.g, node_color.b, alpha))
	var outer_pts: PackedVector2Array = []
	for p in pts:
		outer_pts.append(p * 1.05)
	draw_colored_polygon(outer_pts, Color(node_color.r * 0.3, node_color.g * 0.3, node_color.b * 0.3, 1.0))
	draw_colored_polygon(pts, Color(node_color.r * 0.7, node_color.g * 0.7, node_color.b * 0.7, 1.0))
	var inner_pts: PackedVector2Array = []
	for p in pts:
		inner_pts.append(p * 0.65)
	draw_colored_polygon(inner_pts, Color(node_color.r, node_color.g, node_color.b, 1.0))
	var hi_pts: PackedVector2Array = []
	for i in range(pts.size()):
		var angle: float = (2.0 * PI / pts.size()) * i
		if angle > PI * 1.2 and angle < PI * 1.9:
			hi_pts.append(pts[i] * 0.5 + Vector2(-radius * 0.1, -radius * 0.2))
	if hi_pts.size() >= 3:
		draw_colored_polygon(hi_pts, Color(1.0, 1.0, 1.0, 0.25))
	draw_circle(Vector2(-radius * 0.25, -radius * 0.28), radius * 0.28, Color(1.0, 1.0, 1.0, 0.18))
	draw_circle(Vector2(-radius * 0.28, -radius * 0.32), radius * 0.12, Color(1.0, 1.0, 1.0, 0.7))
	draw_circle(Vector2(-radius * 0.3, -radius * 0.34), radius * 0.05, Color(1.0, 1.0, 1.0, 0.95))
	if is_dragging:
		draw_arc(Vector2.ZERO, radius * 1.35, 0, TAU, 64, Color(node_color.r, node_color.g, node_color.b, 0.7), 2.5)
	if is_pending_connection:
		var pulse: float = abs(sin(_time * 4.0))
		draw_arc(Vector2.ZERO, radius * 1.5, 0, TAU, 64, Color(1.0, 1.0, 1.0, pulse), 2.5)
		draw_arc(Vector2.ZERO, radius * 1.3, 0, TAU, 64, Color(node_color.r, node_color.g, node_color.b, pulse * 0.6), 1.5)
	if is_hovered:
		draw_arc(Vector2.ZERO, radius * 1.5, 0, TAU, 64, Color(node_color.r, node_color.g, node_color.b, 0.5), 2.0)
	if Input.is_key_pressed(KEY_SHIFT) and is_placed:
		var rings: int = 40
		for i in range(rings, 0, -1):
			var t: float = float(i) / rings
			var r: float = 200.0 * t
			var alpha: float = t * t * 0.025
			var fill_pts: PackedVector2Array = []
			for j in range(64):
				var a: float = (TAU / 64) * j
				fill_pts.append(Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(fill_pts, Color(node_color.r, node_color.g, node_color.b, alpha))
		draw_arc(Vector2.ZERO, 200.0, 0, TAU, 128, Color(node_color.r, node_color.g, node_color.b, 0.6), 1.0)

func _get_node_info() -> Dictionary:
	match node_type:
		"흡혈":
			return {name = "흡혈", desc = "가장 가까운 혈체 공격", synergy1 = "결계 연결: 데미지 2배", synergy2 = "증폭 연결: 쿨다운 50%↓", atk = 30, cooldown = 3.0}
		"결계":
			return {name = "결계", desc = "혈체 이동 감속", synergy1 = "흡혈 연결: 데미지 2배", synergy2 = "증폭 연결: 감속 범위 2배", atk = 0, cooldown = 3.0}
		"증폭":
			return {name = "증폭", desc = "인접 노드 강화", synergy1 = "흡혈 연결: 쿨다운 50%↓", synergy2 = "결계 연결: 감속 범위 2배", atk = 0, cooldown = 3.0}
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
	else:
		_return_to_slot()

func _return_to_slot() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", _slot_position, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _do_attack() -> void:
	match node_type:
		"흡혈":
			_attack_nearest_entity(999.0)
		"결계":
			_slow_nearest_entity()
		"증폭":
			_boost_adjacent_nodes()

func _attack_nearest_entity(damage: float) -> void:
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
			nearest.take_damage(final_damage)

func _slow_nearest_entity() -> void:
	var slow_range: float = 200.0
	var slow_duration: float = 3.0
	if synergy_wide_slow:
		slow_range *= 2.0
		slow_duration *= 2.0
	var entities = get_tree().get_nodes_in_group("blood_entities")
	for e in entities:
		if global_position.distance_to(e.global_position) <= slow_range:
			if e.has_method("apply_slow"):
				_spawn_attack_line(e.global_position)
				e.apply_slow(0.5, slow_duration)

func _boost_adjacent_nodes() -> void:
	var nodes = get_tree().get_nodes_in_group("game_nodes")
	for n in nodes:
		if n == self:
			continue
		var d: float = global_position.distance_to(n.global_position)
		if d < 120.0:
			n.attack_cooldown = attack_cooldown * 0.7

func _spawn_attack_line(target_pos: Vector2) -> void:
	var line = Node2D.new()
	line.set_script(preload("res://scripts/AttackLine.gd"))
	line.global_position = Vector2.ZERO
	get_parent().add_child(line)
	line._from = global_position
	line._to = target_pos
	line._color = node_color
```

---

### scripts/ConnectionManager.gd

```gdscript
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
		draw_line(a, b, Color(c.r, c.g, c.b, 0.25), 12.0)
		draw_line(a, b, Color(c.r, c.g, c.b, 0.45), 7.0)
		draw_line(a, b, Color(c.r, c.g, c.b, 0.85), 3.5)
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
		if (conn.from == _pending and conn.to == node) or (conn.from == node and conn.to == _pending):
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
```

---

### scripts/HeartPulse.gd

```gdscript
extends Node2D
class_name HeartPulse

const GRID_COLS: int = 24
const GRID_ROWS: int = 14
const CELL_SIZE: int = 80

var grid_offset: Vector2 = Vector2.ZERO
var _coffin_center: Vector2 = Vector2(960, 540)
var grid: Array = []
var _pulse_time: float = 0.0
var _pulse_interval: float = 5.0
var _pulse_radius: float = 0.0
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
	_pulse_time += delta
	if _pulse_time >= _pulse_interval:
		_pulse_time = 0.0
		_start_pulse()
	if _pulsing:
		_pulse_radius += 600.0 * delta
		var progress: float = _pulse_radius / _max_pulse_radius
		_pulse_alpha = pow(1.0 - progress, 1.5)
		if _pulse_radius >= _max_pulse_radius:
			_pulsing = false
			_pulse_alpha = 0.0
		queue_redraw()

func _start_pulse() -> void:
	_pulse_radius = 0.0
	_pulse_alpha = 1.0
	_pulsing = true

func _draw() -> void:
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
		const BLUR_SPREAD: float = 45.0
		const BLUR_LAYERS: int = 12
		for i in range(BLUR_LAYERS):
			var offset: float = (float(i) / (BLUR_LAYERS - 1) - 0.5) * BLUR_SPREAD * 2.0
			var r: float = _pulse_radius + offset
			if r < 0:
				continue
			var dist_from_peak: float = abs(offset) / BLUR_SPREAD
			var layer_alpha: float = _pulse_alpha * exp(-dist_from_peak * dist_from_peak * 2.0)
			draw_arc(_coffin_center, r, 0, TAU, 128, Color(1.0, 0.2, 0.2, layer_alpha * 0.6), 4.0)
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
				draw_arc(_coffin_center, br, 0, TAU, 128, Color(1.0, 0.15, 0.15, ba), 2.0)
		for r in range(GRID_ROWS + 1):
			var y: float = r * CELL_SIZE
			for c in range(GRID_COLS):
				var seg_center: Vector2 = Vector2(c * CELL_SIZE + CELL_SIZE / 2, y)
				var dist: float = seg_center.distance_to(_coffin_center)
				var diff: float = _pulse_radius - dist
				if diff >= 0 and diff < 120.0:
					var glow: float = (1.0 - diff / 120.0) * _pulse_alpha * 1.2
					glow = clamp(glow, 0.0, 1.0)
					draw_line(Vector2(c * CELL_SIZE, y), Vector2((c + 1) * CELL_SIZE, y), Color(1.0, 0.3, 0.3, glow), 2.5)
		for c in range(GRID_COLS + 1):
			var x: float = c * CELL_SIZE
			for r in range(GRID_ROWS):
				var seg_center: Vector2 = Vector2(x, r * CELL_SIZE + CELL_SIZE / 2)
				var dist: float = seg_center.distance_to(_coffin_center)
				var diff: float = _pulse_radius - dist
				if diff >= 0 and diff < 120.0:
					var glow: float = (1.0 - diff / 120.0) * _pulse_alpha * 1.2
					glow = clamp(glow, 0.0, 1.0)
					draw_line(Vector2(x, r * CELL_SIZE), Vector2(x, (r + 1) * CELL_SIZE), Color(1.0, 0.3, 0.3, glow), 2.5)

func world_to_grid(pos: Vector2) -> Vector2i:
	var col: int = int((pos.x - grid_offset.x) / CELL_SIZE)
	var row: int = int((pos.y - grid_offset.y) / CELL_SIZE)
	return Vector2i(col, row)

func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(grid_offset.x + col * CELL_SIZE + CELL_SIZE / 2, grid_offset.y + row * CELL_SIZE + CELL_SIZE / 2)

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
```

---

### scripts/SynergyEngine.gd

```gdscript
extends Node
class_name SynergyEngine

func _ready() -> void:
	add_to_group("synergy_engine")

func check_synergies(connection_manager: Node) -> void:
	_clear_all_synergies()
	var connections = connection_manager._connections
	for conn in connections:
		var a = conn.from
		var b = conn.to
		if not is_instance_valid(a) or not is_instance_valid(b):
			continue
		_apply_synergy(a, b)

func _clear_all_synergies() -> void:
	for n in get_tree().get_nodes_in_group("game_nodes"):
		n.synergy_double_damage = false
		n.synergy_fast_cooldown = false
		n.attack_cooldown = 3.0
		n.synergy_wide_slow = false

func _apply_synergy(a: Node, b: Node) -> void:
	var types: Array = [a.node_type, b.node_type]
	if types.has("흡혈") and types.has("결계"):
		var absorb = a if a.node_type == "흡혈" else b
		absorb.synergy_double_damage = true
	if types.has("흡혈") and types.has("증폭"):
		var absorb = a if a.node_type == "흡혈" else b
		if not absorb.synergy_fast_cooldown:
			absorb.synergy_fast_cooldown = true
			absorb.attack_cooldown = 1.5
	if types.has("결계") and types.has("증폭"):
		var freeze = a if a.node_type == "결계" else b
		freeze.synergy_wide_slow = true
```

---

### scripts/AttackLine.gd

```gdscript
extends Node2D

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _color: Color = Color.WHITE
var _alpha: float = 0.9

func _process(delta: float) -> void:
	_alpha -= delta * 0.5
	if _alpha <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_line(_from, _to, Color(_color.r, _color.g, _color.b, _alpha), 2.0)
	draw_circle(_to, 4.0, Color(1.0, 1.0, 1.0, _alpha * 0.6))
```

---

### scripts/CoffinParticles.gd

```gdscript
extends Node2D

var _particles: Array = []
var _center: Vector2 = Vector2.ZERO
var _spawn_timer: float = 0.0
const MAX_PARTICLES: int = 35
const SPAWN_INTERVAL: float = 0.18

func setup(coffin_center: Vector2) -> void:
	_center = coffin_center
	position = _center

func _process(delta: float) -> void:
	var coffin = get_tree().get_first_node_in_group("coffin")
	if coffin:
		_center = coffin.global_position + coffin.size / 2
		position = _center
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL and _particles.size() < MAX_PARTICLES:
		_spawn_timer = 0.0
		_spawn_particle()
	var i: int = _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p.pos += p.vel * delta
		p.vel *= 0.96
		p.alpha -= 0.65 * delta
		if p.alpha <= 0:
			_particles.remove_at(i)
		i -= 1
	queue_redraw()

func _spawn_particle() -> void:
	var angle: float = randf_range(0, TAU)
	var dist: float = randf_range(40.0, 160.0)
	var pos: Vector2 = Vector2(cos(angle), sin(angle)) * dist
	var out_dir: Vector2 = pos.normalized()
	var spd: float = randf_range(40.0, 110.0)
	var vel: Vector2 = out_dir * spd + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	var t: float = randf()
	var col: Color = Color(1.0, 0.1, 0.2 + t * 0.8, 0.0)
	_particles.append({
		"pos": pos,
		"vel": vel,
		"size": randf_range(0.75, 2.0),
		"alpha": randf_range(0.5, 1.0),
		"color": col
	})

func _draw() -> void:
	for p in _particles:
		if p.alpha <= 0:
			continue
		var c: Color = p.color
		c.a = p.alpha
		draw_circle(p.pos, p.size, c)
```

---

### scripts/DeathEffect.gd

```gdscript
extends Node2D

var _time: float = 0.0
var _particles: Array = []

func _ready() -> void:
	for i in range(30):
		var angle: float = (TAU / 30.0) * i + randf_range(-0.2, 0.2)
		var speed: float = randf_range(150.0, 450.0)
		var size: float = randf_range(6.0, 18.0)
		_particles.append({
			pos = Vector2.ZERO,
			vel = Vector2(cos(angle), sin(angle)) * speed,
			size = size,
			alpha = 1.0
		})

func _process(delta: float) -> void:
	_time += delta
	var all_dead: bool = true
	for p in _particles:
		p.vel *= 0.93
		p.pos += p.vel * delta
		p.alpha -= 0.9 * delta
		p.size -= 2.0 * delta
		if p.alpha > 0:
			all_dead = false
	if all_dead:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if _time < 0.2:
		var flash_a: float = (0.2 - _time) / 0.2
		draw_circle(Vector2.ZERO, 120.0 * flash_a, Color(1.0, 0.3, 0.3, flash_a * 0.7))
	for p in _particles:
		if p.alpha <= 0 or p.size <= 0:
			continue
		draw_circle(p.pos, max(p.size, 0.5), Color(0.9, 0.05, 0.05, p.alpha))
		var trail: Vector2 = p.pos - p.vel.normalized() * p.size * 2.0
		draw_line(p.pos, trail, Color(1.0, 0.3, 0.3, p.alpha * 0.5), max(p.size * 0.4, 0.5))
	if _time < 0.6:
		var ring_a: float = (0.6 - _time) / 0.6
		var ring_r: float = _time * 500.0
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 64, Color(1.0, 0.2, 0.2, ring_a * 0.8), 2.5)
		draw_arc(Vector2.ZERO, ring_r * 0.7, 0, TAU, 64, Color(1.0, 0.4, 0.4, ring_a * 0.4), 1.5)
```

---

### scripts/ShockwaveShardEffect.gd

```gdscript
extends Node2D
var _vel: Vector2 = Vector2.ZERO
var _alpha: float = 1.0
var _size: float = 6.0
var _gravity: float = 280.0
var _rotation_speed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _spread_sign: float = 1.0

func _ready() -> void:
	_rotation_speed = randf_range(-8.0, 8.0)

func _process(delta: float) -> void:
	var dist: float = global_position.distance_to(_origin)
	var perp: Vector2 = Vector2(-_vel.y, _vel.x).normalized()
	_vel += perp * _spread_sign * dist * 0.002 * delta
	_vel.y += _gravity * delta
	global_position += _vel * delta
	_vel *= 0.97
	_alpha -= 0.7 * delta
	rotation += _rotation_speed * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var s: float = max(_size, 1.0)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 2.0),
		Vector2(s * 0.6, s),
		Vector2(-s * 0.6, s)
	])
	draw_colored_polygon(pts, Color(0.85, 0.05, 0.05, _alpha))
	for i in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], Color(1.0, 0.5, 0.4, _alpha * 0.7), 1.2)
	var trail_pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -s * 1.2),
		Vector2(s * 0.4, s * 0.6),
		Vector2(-s * 0.4, s * 0.6)
	])
	draw_colored_polygon(trail_pts, Color(1.0, 0.2, 0.2, _alpha * 0.25))
```

---

### scripts/ShockwaveRing.gd

```gdscript
extends Node2D
var _radius: float = 10.0
var _alpha: float = 0.8

func _process(delta: float) -> void:
	_radius += 180.0 * delta
	_alpha -= 2.5 * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, _alpha), 3.0)
```

---

### scripts/ShockwaveRingEffect.gd

```gdscript
extends Node2D
var _radius: float = 20.0
var _alpha: float = 0.9
var _delay: float = 0.0
var _started: bool = false
var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	if _time < _delay:
		return
	if not _started:
		_started = true
	_radius += 320.0 * delta
	_alpha -= 2.2 * delta
	if _alpha <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if not _started:
		return
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 64, Color(1.0, 0.15, 0.15, _alpha), 4.0)
	draw_arc(Vector2.ZERO, _radius * 0.85, 0, TAU, 64, Color(1.0, 0.5, 0.5, _alpha * 0.4), 2.0)
```

---

### scripts/ChatManager.gd

```gdscript
class_name ChatManager
extends Node

const DEFAULT_CHAT_SCRIPTS: Array[Dictionary] = [
	{"event": "synergy", "nickname": "VampFan", "message": "시너지 발동이다!!", "color": "#AA00FF"},
	{"event": "crisis", "nickname": "BloodLover", "message": "위기다... 버텨!", "color": "#FF3333"},
	{"event": "gameover", "nickname": "Chatter_01", "message": "끝났네...", "color": "#888888"},
	{"event": "absorb", "nickname": "Viewer42", "message": "흡혈 좀 하네", "color": "#CC0000"},
	{"event": "absorb", "nickname": "Nocturnal", "message": "피다 피!", "color": "#330000"}
]

var _chat_log: VBoxContainer = null
var _chat_scripts: Dictionary = {}
var _event_to_indices: Dictionary = {}

func _ready() -> void:
	print("ChatManager 시작")
	_chat_log = _find_chat_log()
	_load_chat_scripts()
	if _chat_scripts.is_empty():
		_build_default_scripts()

func _find_chat_log() -> VBoxContainer:
	var parent: Node = get_parent()
	if parent:
		var log: Node = parent.get_node_or_null("UILayer/ChatBox/ScrollContainer/ChatLog")
		if log is VBoxContainer:
			return log as VBoxContainer
		var canvas: Node = parent.get_node_or_null("CanvasLayer")
		if canvas:
			log = canvas.get_node_or_null("ChatBox/ScrollContainer/ChatLog")
			if log is VBoxContainer:
				return log as VBoxContainer
	var root: Node = get_tree().root
	return _find_node_recursive(root, "ChatLog") as VBoxContainer

func _find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_node_recursive(child, node_name)
		if found:
			return found
	return null

func _load_chat_scripts() -> void:
	var file: FileAccess = FileAccess.open("res://data/chat_scripts.json", FileAccess.READ)
	if not file:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return
	if data is Array:
		for i in range(data.size()):
			var entry: Dictionary = data[i] if data[i] is Dictionary else {}
			var evt: String = str(entry.get("event", ""))
			if not _event_to_indices.has(evt):
				_event_to_indices[evt] = []
			_event_to_indices[evt].append(i)
			_chat_scripts[str(i)] = entry
	elif data is Dictionary:
		for key in data.keys():
			var entry: Dictionary = data[key] if data[key] is Dictionary else {}
			var evt: String = str(entry.get("event", ""))
			if not _event_to_indices.has(evt):
				_event_to_indices[evt] = []
			_event_to_indices[evt].append(key)
			_chat_scripts[str(key)] = entry

func _scroll_chat_to_bottom(scroll: ScrollContainer) -> void:
	var vbar: ScrollBar = scroll.get_v_scroll_bar()
	if vbar:
		scroll.scroll_vertical = int(vbar.max_value)

func _build_default_scripts() -> void:
	for i in range(DEFAULT_CHAT_SCRIPTS.size()):
		var entry: Dictionary = DEFAULT_CHAT_SCRIPTS[i]
		_chat_scripts[str(i)] = entry
		var evt: String = str(entry.get("event", "absorb"))
		if not _event_to_indices.has(evt):
			_event_to_indices[evt] = []
		_event_to_indices[evt].append(str(i))

func add_chat_message(nickname: String, message: String, color: String) -> void:
	if not _chat_log:
		return
	var label: Label = Label.new()
	label.text = "[%s] %s" % [nickname, message]
	label.add_theme_color_override("font_color", Color.from_string(color, Color.WHITE))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chat_log.add_child(label)
	var scroll: ScrollContainer = _chat_log.get_parent() as ScrollContainer
	if scroll:
		call_deferred("_scroll_chat_to_bottom", scroll)

func trigger_event_chat(event_type: String) -> void:
	var indices: Array = _event_to_indices.get(event_type, [])
	if indices.is_empty():
		return
	var key: Variant = indices[randi() % indices.size()]
	var entry: Dictionary = _chat_scripts.get(str(key), {})
	if entry.is_empty():
		return
	var nick: String = str(entry.get("nickname", "Viewer"))
	var msg: String = str(entry.get("message", "..."))
	var col: String = str(entry.get("color", "#FFFFFF"))
	add_chat_message(nick, msg, col)
```

---

### scripts/AutoAbsorb.gd

```gdscript
class_name AutoAbsorb
extends Node

signal automation_level_changed(new_level: int)
signal auto_cycle_triggered()

const LEVEL_TIMER_WAIT: Dictionary = {
	1: 0.0,
	2: 30.0,
	3: 10.0,
	4: 5.0
}

var _current_level: int = 1
var _connection_count: int = 0
var _synergy_count: int = 0
var _timer: Timer = null
var _synergy_engine: Node = null
var _node_grid: Node = null

func _ready() -> void:
	print("AutoAbsorb 시작")
	_setup_timer()
	call_deferred("_connect_signals")

func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func _connect_signals() -> void:
	_synergy_engine = _find_node_of_type("SynergyEngine")
	if _synergy_engine and _synergy_engine.has_signal("synergy_activated"):
		_synergy_engine.synergy_activated.connect(_on_synergy_activated)
	_node_grid = _find_node_of_type("HeartPulse")
	if _node_grid and _node_grid.has_signal("connection_made"):
		_node_grid.connection_made.connect(_on_connection_made)
	_evaluate_level()

func _find_node_of_type(type_name: String) -> Node:
	var root: Node = get_tree().root
	return _find_node_recursive(root, type_name)

func _find_node_recursive(node: Node, type_name: String) -> Node:
	var script_res: Script = node.get_script()
	if script_res is GDScript:
		if (script_res as GDScript).get_global_name() == type_name:
			return node
	for child: Node in node.get_children():
		var found: Node = _find_node_recursive(child, type_name)
		if found:
			return found
	return null

func _on_synergy_activated(synergy_id: String, effect_data: Dictionary) -> void:
	_synergy_count += 1
	_evaluate_level()

func _on_connection_made(node_a: String, node_b: String) -> void:
	_connection_count += 1
	_evaluate_level()

func _evaluate_level() -> void:
	var new_level: int = _compute_level()
	if new_level == _current_level:
		_update_timer_for_level()
		return
	_current_level = new_level
	automation_level_changed.emit(_current_level)
	_update_timer_for_level()

func _compute_level() -> int:
	if _synergy_count >= 3:
		return 4
	if _synergy_count >= 1:
		return 3
	if _connection_count >= 2:
		return 2
	return 1

func _update_timer_for_level() -> void:
	var wait_time: float = LEVEL_TIMER_WAIT.get(_current_level, 0.0)
	if wait_time <= 0.0:
		_timer.stop()
		return
	if not _timer.is_stopped():
		_timer.stop()
	_timer.wait_time = wait_time
	_timer.start()

func _on_timer_timeout() -> void:
	auto_cycle_triggered.emit()
	_update_timer_for_level()

func get_current_level() -> int:
	return _current_level

func get_connection_count() -> int:
	return _connection_count

func get_synergy_count() -> int:
	return _synergy_count
```

---

### scripts/BloodEntityDeathEffect.gd

```gdscript
extends Node2D

var _particles: Array = []

func _ready() -> void:
	for i in range(12):
		var angle: float = randf_range(0, TAU)
		var spd: float = randf_range(120.0, 280.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"size": randf_range(4.0, 10.0),
			"alpha": randf_range(0.8, 1.0)
		})

func _process(delta: float) -> void:
	var all_dead: bool = true
	for p in _particles:
		p.pos += p.vel * delta
		p.vel *= 0.88
		p.alpha -= 1.8 * delta
		if p.alpha > 0:
			all_dead = false
	if all_dead:
		queue_free()
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		if p.alpha <= 0:
			continue
		var c: Color = Color(0.9, 0.1, 0.1, p.alpha)
		draw_circle(p.pos, p.size, c)
		draw_circle(p.pos, p.size * 0.5, Color(1.0, 0.3, 0.3, p.alpha * 0.7))
```

---

## 2. 모든 .tscn 파일 씬 트리 구조

### scenes/Main.tscn

```
Main (Node2D)
├── Background (ColorRect)
├── EntityLayer (Node2D)
│   ├── HeartPulse (instance: HeartPulse.tscn)
│   └── ConnectionManager (Node2D)
└── CanvasLayer (CanvasLayer)
    ├── TopBar (Panel)
    │   ├── LiveDot (Label)
    │   ├── LiveText (Label)
    │   ├── TimerLabel (Label)
    │   └── BloodLabel (Label)
    ├── Coffin (ColorRect) [groups: coffin]
    ├── CoffinHPBar (Control)
    │   ├── BG (ColorRect)
    │   ├── DamageBar (ColorRect)
    │   ├── HPFill (ColorRect)
    │   └── HPBarLabel (Label)
    ├── LeftTab (ColorRect)
    │   ├── KeyBox (Panel)
    │   │   └── Label (Label)
    │   ├── Icon1 (Label)
    │   ├── Icon2 (Label)
    │   ├── Icon3 (Label)
    │   └── Icon4 (Label)
    ├── LeftPanel (Panel)
    │   ├── Card1_Resources (Panel)
    │   │   └── ResourcesVBox (VBoxContainer)
    │   │       ├── BloodRow (HBoxContainer)
    │   │       │   ├── BloodLabel (Label)
    │   │       │   └── BloodValue (Label)
    │   │       └── SpecialRow (HBoxContainer)
    │   │           ├── SpecialLabel (Label)
    │   │           └── SpecialValue (Label)
    │   ├── Card2_Automation (Panel)
    │   │   ├── AutoLabel (Label)
    │   │   ├── LvLabel (Label)
    │   │   └── AutoProgressBar (ProgressBar)
    │   ├── Card3_NodeSlots (Panel)
    │   │   ├── NodeSlotLabel (Label)
    │   │   ├── NodeSlot1 (Panel)
    │   │   │   └── Label (Label)
    │   │   ├── NodeSlot2 (Panel)
    │   │   │   └── Label (Label)
    │   │   ├── NodeSlot3 (Panel)
    │   │   │   └── Label (Label)
    │   │   ├── NodeSlot4 (Panel)
    │   │   │   └── Label (Label)
    │   │   ├── NodeSlot5 (Panel)
    │   │   │   └── Label (Label)
    │   │   └── NodeSlot6 (Panel)
    │   │       └── Label (Label)
    │   └── Card4_DeckSlots (Panel)
    │       ├── DeckSlotLabel (Label)
    │       ├── DeckSlot1 (Panel)
    │       │   ├── ColorIndicator (ColorRect)
    │       │   └── Label (Label)
    │       ├── DeckSlot2 (Panel)
    │       │   ├── ColorIndicator (ColorRect)
    │       │   └── Label (Label)
    │       └── DeckSlot3 (Panel)
    │           ├── ColorIndicator (ColorRect)
    │           └── Label (Label)
    ├── RightTab (ColorRect)
    │   ├── KeyBox (Panel)
    │   │   └── Label (Label)
    │   ├── Icon1 (Label)
    │   └── Icon2 (Label)
    ├── RightPanel (Panel)
    │   ├── VelmireFacecam (ColorRect)
    │   │   ├── FacecamPlaceholder (Panel)
    │   │   └── VelmireLabel (Label)
    │   └── ChatBox (Panel)
    │       ├── ChatLabel (Label)
    │       └── ScrollContainer (ScrollContainer)
    │           └── ChatLog (VBoxContainer)
    ├── HintArea (Control)
    │   └── DotsContainer (Control)
    ├── HintPopup (PanelContainer)
    │   └── HintLabel (Label)
    ├── VignetteOverlay (ColorRect)
    └── TooltipBar (ColorRect)
        ├── TopBorder (ColorRect)
        ├── NodeName (Label)
        ├── NodeDesc (Label)
        ├── Divider1 (ColorRect)
        ├── SynergyTitle (Label)
        ├── Synergy1 (Label)
        ├── Synergy2 (Label)
        ├── Divider2 (ColorRect)
        ├── StatTitle (Label)
        ├── StatATK (Label)
        └── StatCooldown (Label)
```

---

### scenes/BloodDrop.tscn

```
BloodDrop (Node2D)
```

---

### scenes/BloodEntity.tscn

```
BloodEntity (Node2D)
```

---

### scenes/Coffin.tscn

```
Coffin (Area2D) [임베디드 스크립트]
├── CollisionShape2D (CollisionShape2D)
└── Sprite2D (Sprite2D)
```

**Coffin.tscn 임베디드 스크립트 (sub_resource GDScript):**
```gdscript
extends Area2D

signal coffin_damaged(current_hp: float, max_hp: float)
signal game_over

@export var max_hp: float = 100.0
var current_hp: float = 100.0

func _ready() -> void:
	print("Coffin 시작")
	current_hp = max_hp
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var script_res = body.get_script()
	if script_res is GDScript and (script_res as GDScript).get_global_name() == "BloodEntityAI":
		var entity_data: Dictionary = body.get("entity_data") if body.get("entity_data") else {}
		var damage: float = float(entity_data.get("damage", 10))
		take_damage(damage)
		body.queue_free()

func take_damage(amount: float) -> void:
	current_hp -= amount
	coffin_damaged.emit(current_hp, max_hp)
	if current_hp <= 0:
		game_over.emit()
```

---

### scenes/GameNode.tscn

```
GameNode (Node2D)
```

---

### scenes/GameWorld.tscn

```
GameWorld (Node2D)
└── Coffin (instance: Coffin.tscn)
```

---

### scenes/HeartPulse.tscn

```
HeartPulse (Node2D)
```

---

### scenes/StreamUI.tscn

```
StreamUI (Node)
├── CanvasLayer (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   ├── LiveLabel (Label)
│   │   └── ViewersCount (Label)
│   ├── ChatBox (VBoxContainer)
│   │   └── ScrollContainer (ScrollContainer)
│   │       └── ChatLog (VBoxContainer)
│   ├── HUD (HBoxContainer)
│   │   ├── BloodDisplay (Label)
│   │   ├── SpecialDisplay (Label)
│   │   ├── TimerDisplay (Label)
│   │   └── NodeSlotsDisplay (Label)
│   └── VelmireReaction (TextureRect)
└── ChatManager (Node)
```

---

### scenes/VelmireReaction.tscn

```
VelmireReaction (Node)
```

---

### velmire.tscn

```
Node2D (Node2D)
```

---

## 3. Autoload 등록 목록

| 이름 | 경로 |
|------|------|
| ResourceManager | res://scripts/ResourceManager.gd |

---

## 4. 그룹 등록 현황

### 스크립트에서 add_to_group()

| 그룹명 | 등록 위치 |
|--------|-----------|
| main | Main.gd `_ready()` |
| game_nodes | GameNode.gd `_ready()` |
| connection_manager | ConnectionManager.gd `_ready()` |
| heart_pulse | HeartPulse.gd `_ready()` |
| synergy_engine | SynergyEngine.gd `_ready()` |
| blood_entities | Main.gd `_spawn_blood_entity()` (동적 추가) |

### 씬 파일에서 groups = []

| 그룹명 | 등록 위치 |
|--------|-----------|
| coffin | Main.tscn - Coffin (ColorRect) 노드 |

### 기타 (remove_from_group)

- blood_entities: BloodEntityAI.gd `take_damage()` 시, Main.gd `_check_coffin_collision()` 시 제거

---

## 5. 각 스크립트의 주요 함수 목록

### Main.gd
- `_ready()` - 그룹 등록, 초기화, 패널 설정, UI 연결
- `show_tooltip()` / `hide_tooltip()` - 툴팁 표시/숨김
- `_spawn_start_nodes()` - 시작 노드(흡혈, 결계) 스폰
- `_build_hint_dots()` - 노드 슬롯 UI 생성 (흡혈10/결계15/증폭20)
- `_spawn_node_from_slot()` - 슬롯 클릭 시 노드 스폰
- `_spawn_blood_entity()` - 혈체 스폰
- `_check_coffin_collision()` - 관 충돌 검사, HP 감소, 쇼크웨이브
- `_show_hp_bar()` / `_fade_hp_bar()` - HP 바 표시/페이드
- `_trigger_shake()` / `_apply_shake()` - 카메라 흔들림
- `_trigger_vignette()` - 비네팅 효과
- `_trigger_shockwave()` - 쇼크웨이브 파편 이펙트
- `_game_over()` - 게임 오버 시퀀스
- `_slide_left_open/close()` / `_slide_right_open/close()` - 패널 슬라이드
- `_on_blood_changed()` / `_on_special_changed()` - 재화 UI 업데이트
- `update_blood_ui()` - TopBar 혈액 표시

### ResourceManager.gd
- `add_blood()` / `add_special()` - 재화 추가
- `add_resource()` - 타입별 재화 추가
- `spend_blood()` / `spend_special()` - 재화 소비
- `get_all()` - 전체 재화 반환

### BloodEntityAI.gd
- `_generate_points()` - 혈체 형태 점 생성
- `_get_smooth_points()` - 부드러운 폴리곤
- `take_damage()` - 데미지 처리, HP바, 사망 시 이펙트/드롭
- `_spawn_death_effect()` - DeathEffect 스폰
- `_drop_blood()` - BloodDrop 3개 스폰 (value 1.0)
- `_spawn_damage_number()` - 데미지 숫자 표시
- `apply_slow()` - 감속 적용
- `is_slowed()` - 감속 상태 반환

### BloodDrop.gd
- `setup()` - 위치, 값, 타깃 설정, 버스트 방향 계산
- `_process()` - burst→suck 페이즈 전환, 목표 흡수 시 ResourceManager.add_blood()

### GameNode.gd
- `_generate_base_points()` - 노드 형태 점
- `_input()` - 드래그, Shift+클릭 연결, 배치/제거
- `_get_node_info()` - 툴팁용 노드 정보
- `_try_place_on_grid()` - 그리드에 배치
- `_do_attack()` - 흡혈/결계/증폭 공격 분기
- `_attack_nearest_entity()` - 200 거리 내 최근 혈체 공격 (999 데미지)
- `_slow_nearest_entity()` - 200 거리 내 혈체 감속
- `_boost_adjacent_nodes()` - 120 거리 내 인접 노드 쿨다운 70%
- `_spawn_attack_line()` - AttackLine 이펙트

### ConnectionManager.gd
- `try_connect()` - Shift+클릭으로 노드 연결/해제
- `disconnect_node()` - 노드 연결 해제
- `_notify_synergy_engine()` - 시너지 엔진 갱신
- `get_connections_for()` - 노드의 연결 목록

### HeartPulse.gd
- `setup()` - 관 중심 설정
- `world_to_grid()` / `grid_to_world()` - 좌표 변환
- `is_valid_cell()` / `is_cell_empty()` - 셀 검사
- `place_node()` / `remove_node()` - 그리드 배치/제거
- `_start_pulse()` - 펄스 시작

### SynergyEngine.gd
- `check_synergies()` - 연결 기반 시너지 재계산
- `_clear_all_synergies()` - 시너지 플래그 초기화
- `_apply_synergy()` - 흡혈+결계(2배), 흡혈+증폭(쿨50%), 결계+증폭(감속2배)

### AttackLine.gd
- `_process()` - 알파 감소, 사라짐
- `_draw()` - 공격 라인 그리기

### CoffinParticles.gd
- `setup()` - 관 중심 설정
- `_spawn_particle()` - 관 주변 파티클 스폰

### DeathEffect.gd
- `_ready()` - 30개 파편 초기화
- `_process()` - 파편 이동, 페이드아웃

### ShockwaveShardEffect.gd
- `_process()` - 중력, 스프레드, 페이드
- `_draw()` - 삼각형 파편

### ShockwaveRing.gd / ShockwaveRingEffect.gd
- `_process()` - 반지름 확대, 페이드
- `_draw()` - arc 그리기

### ChatManager.gd
- `_find_chat_log()` - ChatLog VBoxContainer 찾기
- `_load_chat_scripts()` - data/chat_scripts.json 로드
- `add_chat_message()` - 채팅 메시지 추가
- `trigger_event_chat()` - 이벤트 타입별 채팅 트리거

### AutoAbsorb.gd
- `_connect_signals()` - SynergyEngine, HeartPulse 시그널 연결
- `_evaluate_level()` - 연결/시너지 수 기반 레벨 계산
- `get_current_level()` / `get_connection_count()` / `get_synergy_count()` - 상태 반환

### BloodEntityDeathEffect.gd
- `_ready()` - 12개 파편 초기화
- `_process()` - 파편 이동, 페이드 (현재 미사용)

---

## 참고 사항

- **Coffin.tscn** 내부 임베디드 스크립트는 Main.tscn의 Coffin(ColorRect)과 별개. Main은 ColorRect를 사용하고 `coffin` 그룹으로 참조.
- **main scene**: `res://scenes/Main.tscn`
- **Viewport**: 1920×1080
