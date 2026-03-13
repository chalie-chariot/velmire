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
var _hints: Array = [
	"💡 Shift + 클릭으로 노드를 연결할 수 있어요",
	"💡 흡혈 + 결계 연결 시 감속된 혈체에 데미지 2배",
	"💡 흡혈 + 증폭 연결 시 공격 쿨다운 50% 감소",
	"💡 결계 + 증폭 연결 시 감속 범위와 지속시간 2배",
	"💡 Shift를 누르면 노드의 공격 범위를 확인할 수 있어요",
	"💡 노드는 스킬 트리로 강화시킬 수 있어요",
	"💡 관을 지키세요! HP가 0이 되면 게임오버",
]
var _selected_hint: int = -1
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
	_spawn_test_nodes()
	var synergy_engine = SynergyEngine.new()
	add_child(synergy_engine)
	_build_hint_dots()
	update_blood_ui(ResourceManager.blood)

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

func _build_hint_dots() -> void:
	var dot_size: int = 40
	var spacing: int = 56
	var total_width: int = _hints.size() * spacing
	var start_x: int = (1920 - total_width) / 2

	for i in range(_hints.size()):
		var dot: Button = Button.new()
		dot.custom_minimum_size = Vector2(dot_size, dot_size)
		dot.size = Vector2(dot_size, dot_size)
		dot.position = Vector2(start_x + i * spacing, 30)

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.4, 0.05, 0.05, 0.85)
		style.set_corner_radius_all(20)
		dot.add_theme_stylebox_override("normal", style)
		dot.add_theme_stylebox_override("hover",
			_make_dot_style(Color(0.8, 0.15, 0.15, 0.95)))
		dot.add_theme_stylebox_override("pressed",
			_make_dot_style(Color(1.0, 0.3, 0.3, 1.0)))
		var idx: int = i
		dot.pressed.connect(func(): _on_dot_pressed(idx))
		dot.modulate = Color(1, 1, 1, 0)
		_dots_container.add_child(dot)

func _make_dot_style(color: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(20)
	return s

func _on_dot_pressed(index: int) -> void:
	_hint_label.text = _hints[index]
	_hint_popup.visible = true
	_hint_popup.modulate = Color(1, 1, 1, 0)
	_hint_popup.position = Vector2(_hint_popup.position.x, 930.0)
	var tween: Tween = create_tween()
	tween.tween_property(_hint_popup, "position:y", 900.0, 0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(_hint_popup, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_interval(4.0)
	tween.tween_property(_hint_popup, "modulate", Color(1, 1, 1, 0), 0.4
	).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _hint_popup.visible = false)

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
	if my > 880:
		_hint_hiding = false
		if not _hint_area.visible:
			_hint_area.visible = true
			_hint_area.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 980.0)

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

func _spawn_test_nodes() -> void:
	var node_scene = preload("res://scenes/GameNode.tscn")
	var types = [
		{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1)},
		{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9)},
		{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2)},
	]
	for i in range(3):
		var node = node_scene.instantiate()
		node.node_id = types[i]["id"]
		node.node_type = types[i]["type"]
		node.node_color = types[i]["color"]
		node._slot_position = Vector2(100, 300 + i * 120)
		node.global_position = node._slot_position
		$EntityLayer.add_child(node)

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
