extends Node2D

@onready var blood_entity_scene = preload("res://scenes/BloodEntity.tscn")
@onready var _coffin_rect: ColorRect = $CanvasLayer/Coffin
@onready var _vignette: ColorRect = $CanvasLayer/VignetteOverlay
@onready var _live_dot: Label = $CanvasLayer/TopBar/LiveDot
@onready var _blood_label: Label = $CanvasLayer/TopBar/BloodLabel
@onready var _timer_label: Label = $CanvasLayer/TopBar/TimerLabel
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
@onready var _viewer_label: Label = $CanvasLayer/RightPanel/ViewerBar/ViewerLabel
@onready var _like_label: Label = $CanvasLayer/RightPanel/ViewerBar/LikeLabel
@onready var _left_blood_label: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow/BloodValue
@onready var _left_ruby_label: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/RubyRow/RubyValue
@onready var _owned_container: VBoxContainer = $CanvasLayer/LeftPanel/OwnedNodesContainer

var _owned_nodes: Array = [
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1)},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9)},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2)},
]
var _left_tween: Tween
var _right_tween: Tween
var _hp_tween: Tween
var _damage_tween: Tween
var _coffin_push_tween: Tween
const _coffin_base_pos: Vector2 = Vector2(920.0, 480.0)
var left_open: bool = false
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
var _shake_offset: Vector2 = Vector2.ZERO
var _vignette_tween: Tween
var _displayed_blood: float = 0.0
var _last_blood_value: float = -1.0  # 이전 혈액값 (스케일 조건: |diff| >= 5)
var _blood_tween: Tween
var _blood_anim_tween: Tween
var _upgrade_scale_tween: Tween  # 파티클 흡수 시 바운스용
var _last_delta: float = 0.016
var _blood_counter_ref: Label
var _node_slots: Array = [
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "cost": 10},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "cost": 15},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "cost": 20},
	{"id": "absorb", "type": "흡혈", "color": Color(0.9, 0.1, 0.1), "cost": 12},
	{"id": "freeze", "type": "결계", "color": Color(0.1, 0.3, 0.9), "cost": 18},
	{"id": "resonate", "type": "증폭", "color": Color(0.1, 0.8, 0.2), "cost": 22},
]
var _unlocked_slots: int = 3  # 초기 3개
var _max_slots: int = 6       # 최대 6개
const _num_node_type_slots: int = 3  # 구매 가능 노드 종류 수 (흡혈/결계/증폭) — 그 외는 빈 슬롯
const _slot_unlock_costs: Array = [20, 33, 45]  # 슬롯 4·5·6 해금 비용

const TOOLTIP_BLOOD = {
	"title": "🩸 혈액",
	"desc": "런 내 기본 재화. 런 종료 시 초기화됩니다.",
	"details": [
		"노드 소환 / 슬롯 해금 / 노드 강화에 사용",
		"관 범위 안에서 처치 시 +3 + 기본량의 50% 보너스",
		"시청자 100명: 혈액 2배 10초",
		"시청자 500명: 혈액 2배 20초",
		"시청자 1000명+: 혈액 2배 30초",
	]
}

const TOOLTIP_RUBY = {
	"title": "🔴 루비 (블러디아 루비)",
	"desc": "영속 이월 재화. 런이 끝나도 유지됩니다.",
	"details": [
		"15콤보 달성  →  +1",
		"퍼펙트 디펜스 (30초 무피격, HP 100%)  →  +1",
		"클리어 (2분 제한, 관 HP 유지)  →  +3",
		"RubinaTap 자동 생산  →  +1~수량 (cap 5~18)",
		"후원 소액  →  +1 / 중액  →  +2 / 고액  →  +3",
		"슈퍼챗  →  50% 확률",
	]
}

const TOOLTIP_CHIP = {
	"title": "◆ 블러디아 칩",
	"desc": "보류",
	"details": []
}

const TOOLTIP_RINGLIGHT = {
	"title": "💡 링라이트",
	"desc": "루비 2개로 배치. 60초 유지, 범위 300px.",
	"details": [
		"관·링라이트 범위 내 노드 배치 가능",
		"HeartPulse가 범위 내 노드에 랜덤 버프 적용",
		"버프: 쿨다운 / 데미지 / 범위 / 혈액 (10초 쿨)",
	]
}

const TOOLTIP_RUBINA_TAP = {
	"title": "🔴 루비나 탭",
	"desc": "주기적으로 루비를 생산하는 시설.",
	"details": [
		"일정 간격(3초)마다 cap 수만큼 루비 생성",
		"탭 인덱스별 cap 5~18, 칩 확률 0~5%",
		"누적 시 아이콘 부유 → 클릭 시 UI로 흡수",
	]
}

var _hint_hiding: bool = false
var _hint_hide_tweens: Array = []
var _unlock_animation_playing: bool = false  # 해금 애니 중엔 인디케이터 숨기지 않음
var _unlock_in_progress: bool = false  # 슬롯 연속 해금 시 중복 실행 방지
var _indicator_was_hidden: bool = true
var _pending_spawn_index: int = -1  # 재화 차감됐지만 아직 스폰 안된 슬롯 (중복 방지)
var _slots_in_panel: bool = false  # X키로 슬롯이 Q 패널로 회수된 상태
var _slot_data: Array[String] = ["", "", "", "", "", ""]  # 6개 인디케이터 슬롯
var _selected_nodes: Array = []
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_duration: float = 3.0  # 3초 안에 다음 처치 없으면 콤보 리셋
var _hitstop_timer: float = 0.0

# ===== 난이도 단계 (30초마다 증가) =====
# 단계 0~3   혈체(血體)   기본 핏덩어리
# 단계 4~5   기혈(寄血)   기생하는 피 - 핵이 숙주처럼 내부에 자리잡음
# 단계 6~7   숙혈(宿血)   숙주가 된 피 - 줄기가 뻗어 주변을 잠식
# 단계 8~9   침혈(侵血)   침식하는 피 - 완전히 다른 형태로 변이
# 단계 10+   혈왕(血王)   모든 혈체를 지배하는 존재
# ------------------------------------------
# 단계 0 (0~30초):  스폰간격 4.0s / 최대 4개 / HP 60  / 속도 45 / radius 27
# 단계 1 (30~60초): 스폰간격 3.65s / 최대 5개 / HP 80  / 속도 52 / radius 29
# 단계 2 (60~90초): 스폰간격 3.3s  / 최대 6개 / HP 100 / 속도 59 / radius 31
# 단계 3 (90~120s): 스폰간격 2.95s / 최대 7개 / HP 120 / 속도 66 / radius 33
# 단계 4 (120~150s): 기혈 스폰 시작
#                   스폰간격 2.6s  / 최대 8개 / HP 140 / 속도 73 / radius 35
# 단계 5 (150s+):   스폰간격 2.25s / 최대 9개 / HP 160 / 속도 80 / radius 37
# ==========================================
var _elapsed_time: float = 0.0
var _round_time: float = 120.0
var _remaining_time: float = 120.0
var _viewers: int = 0
var _likes: int = 0
var _viewer_timer: float = 0.0
var _like_timer: float = 0.0
var _prev_difficulty: int = 0
var _danger_chat_sent: bool = false
var _kill_count: int = 0
var _ai_chat_started: bool = false
var _state_timer: float = 0.0
var _no_hit_timer: float = 0.0
var _perfect_defense_notified: bool = false
var _map_vignette_overlay: ColorRect = null
var _tooltip_node: Control = null
var _tooltip_tween: Tween = null
var _node_info_panel: Control = null
var _coffin_barrier_active: bool = false
const _tooltip_width: float = 690.0
const _tooltip_height: float = 180.0

func _ready() -> void:
	add_to_group("main")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2
	$EntityLayer/HeartPulse.setup(coffin_center)
	var coffin_particles: Node2D = Node2D.new()
	coffin_particles.set_script(preload("res://scripts/CoffinParticles.gd"))
	coffin_particles.setup(coffin_center)
	$EntityLayer.add_child(coffin_particles)
	$CanvasLayer/LeftPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/RightPanel.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/LeftTab.gui_input.connect(_on_left_tab_gui_input)
	$CanvasLayer/RightTab.gui_input.connect(_on_right_tab_gui_input)
	$CanvasLayer/CoffinHPBar.modulate = Color(1, 1, 1, 0)
	_hint_popup.visible = false
	_spawn_start_nodes()
	var synergy_engine = SynergyEngine.new()
	add_child(synergy_engine)
	var chat_manager = ChatManager.new()
	add_child(chat_manager)
	var chat_log: RichTextLabel = $CanvasLayer/RightPanel/ChatBox/ScrollContainer/ChatLog as RichTextLabel
	chat_manager.setup(chat_log)
	chat_manager.send_chat("start")
	_build_hint_dots()
	_build_owned_nodes()
	_update_slot_count_label()
	$CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow.modulate = Color(1, 1, 1, 0.5)
	ResourceManager.blood_changed.connect(_on_blood_changed)
	ResourceManager.blood_changed.connect(update_blood_ui)
	ResourceManager.special_changed.connect(_on_special_changed)
	ResourceManager.chip_changed.connect(_on_chip_changed)
	_on_blood_changed(ResourceManager.blood)
	_displayed_blood = ResourceManager.blood
	update_blood_ui(ResourceManager.blood)
	_on_special_changed(ResourceManager.special)
	_on_chip_changed(ResourceManager.chip)
	_init_viewers()
	update_ruby_ui(ResourceManager.ruby)

	var blood_row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow
	var ruby_row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/RubyRow
	var chip_row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow
	var rubina_tap_card: Control = $CanvasLayer/LeftPanel.get_node_or_null("Card2_Automation")
	blood_row.mouse_filter = Control.MOUSE_FILTER_STOP
	ruby_row.mouse_filter = Control.MOUSE_FILTER_STOP
	chip_row.mouse_filter = Control.MOUSE_FILTER_STOP
	if rubina_tap_card:
		rubina_tap_card.mouse_filter = Control.MOUSE_FILTER_STOP
		rubina_tap_card.mouse_entered.connect(_on_rubina_tap_card_mouse_entered)
		rubina_tap_card.mouse_exited.connect(_on_resource_tooltip_exited)
	blood_row.mouse_entered.connect(_on_blood_row_mouse_entered)
	blood_row.mouse_exited.connect(_on_resource_tooltip_exited)
	ruby_row.mouse_entered.connect(_on_ruby_row_mouse_entered)
	ruby_row.mouse_exited.connect(_on_resource_tooltip_exited)
	chip_row.mouse_entered.connect(_on_chip_row_mouse_entered)
	chip_row.mouse_exited.connect(_on_resource_tooltip_exited)

	var viewer_bar: Control = $CanvasLayer/RightPanel/ViewerBar
	var right_panel: Control = $CanvasLayer/RightPanel
	viewer_bar.position = Vector2(0, right_panel.size.y - 40)

	# 맵 전체 암전 (화면 중심→가장자리 서서히 어두워짐, 항상 표시)
	_map_vignette_overlay = ColorRect.new()
	_map_vignette_overlay.name = "MapVignetteOverlay"
	_map_vignette_overlay.position = Vector2.ZERO
	_map_vignette_overlay.size = Vector2(1920, 1080)
	_map_vignette_overlay.color = Color(0, 0, 0, 0)
	_map_vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_shader = load("res://shaders/map_vignette.gdshader") as Shader
	if vignette_shader:
		var mat = ShaderMaterial.new()
		mat.shader = vignette_shader
		mat.set_shader_parameter("viewport_size", Vector2(1920, 1080))
		mat.set_shader_parameter("darken_strength", 0.45)
		mat.set_shader_parameter("bright_radius_0", 0.0)
		mat.set_shader_parameter("bright_radius_1", 0.0)
		_map_vignette_overlay.material = mat
	$CanvasLayer.add_child(_map_vignette_overlay)
	$CanvasLayer.move_child(_map_vignette_overlay, 0)
	_map_vignette_overlay.z_index = -1000
	_map_vignette_overlay.add_to_group("map_vignette_overlay")

## 아이템으로 암전의 특정 영역을 밝힐 때 사용. area_index: 0 또는 1, center: 화면 좌표, radius: 밝은 반경(px), strength: 0~1
func set_vignette_bright_area(area_index: int, center: Vector2, radius: float, strength: float = 1.0) -> void:
	if not _map_vignette_overlay or not (_map_vignette_overlay.material is ShaderMaterial):
		return
	var mat: ShaderMaterial = _map_vignette_overlay.material
	if area_index == 0:
		mat.set_shader_parameter("bright_center_0", center)
		mat.set_shader_parameter("bright_radius_0", radius)
		mat.set_shader_parameter("bright_strength_0", strength)
	elif area_index == 1:
		mat.set_shader_parameter("bright_center_1", center)
		mat.set_shader_parameter("bright_radius_1", radius)
		mat.set_shader_parameter("bright_strength_1", strength)

## 밝은 영역 해제
func clear_vignette_bright_area(area_index: int) -> void:
	if not _map_vignette_overlay or not (_map_vignette_overlay.material is ShaderMaterial):
		return
	var mat: ShaderMaterial = _map_vignette_overlay.material
	if area_index == 0:
		mat.set_shader_parameter("bright_radius_0", 0.0)
	elif area_index == 1:
		mat.set_shader_parameter("bright_radius_1", 0.0)

func _register_ring_light(ring: Node2D) -> void:
	var lights = get_tree().get_nodes_in_group("ring_light")
	var placed: Array = []
	for l in lights:
		if "is_placed" in l and l.is_placed:
			placed.append(l)
	var idx = placed.size() - 1
	if "shader_index" in ring:
		ring.shader_index = idx

	if _map_vignette_overlay and _map_vignette_overlay.material:
		if idx == 0:
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_center_0", ring.global_position)
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_radius_0", ring.range_radius)
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_strength_0", 2.0)
		elif idx == 1:
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_center_1", ring.global_position)
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_radius_1", ring.range_radius)
			_map_vignette_overlay.material.set_shader_parameter(
				"bright_strength_1", 2.0)
	_build_owned_nodes()

func _spawn_ring_light() -> void:
	var RingLightScript = preload("res://scripts/RingLight.gd")
	var ring = RingLightScript.new()
	ring.global_position = get_viewport().get_mouse_position()
	ring.is_dragging = true
	$EntityLayer.add_child(ring)
	_build_owned_nodes()

func show_tooltip(info: Dictionary, node_color: Color, node: Node2D = null) -> void:
	var level_text: String = ""
	if node and node.get("upgrade_level") != null:
		level_text = "  LV.%d" % (node.upgrade_level + 1)
	_tip_name.text = info.name + level_text
	_tip_desc.text = info.desc
	_tip_syn1.text = "◆ " + info.synergy1
	_tip_syn2.text = "◆ " + info.synergy2
	_stat_atk.text = "⚔ 공격력: " + str(info.atk)
	_stat_cd.text = "⏱ 쿨다운: " + str(info.cooldown) + "s"
	_tip_name.add_theme_font_size_override("font_size", 24)
	_tip_desc.add_theme_font_size_override("font_size", 18)
	_tip_syn1.add_theme_font_size_override("font_size", 18)
	_tip_syn2.add_theme_font_size_override("font_size", 18)
	_stat_atk.add_theme_font_size_override("font_size", 18)
	_stat_cd.add_theme_font_size_override("font_size", 18)
	_tip_syn1.add_theme_color_override("font_color", node_color.lightened(0.3))
	_tip_syn2.add_theme_color_override("font_color", node_color.lightened(0.3))

	# 관 기준 좌/우에 따라 하단 설명창 위치 결정 (고정 위치로 정확히 배치)
	var viewport_width: float = get_viewport_rect().size.x
	var viewport_height: float = get_viewport_rect().size.y
	var bar_bottom: float = viewport_height
	var bar_top: float = bar_bottom - _tooltip_height
	var bar_width: float = _tooltip_width

	var coffin_center_x: float = _coffin_rect.global_position.x + _coffin_rect.size.x / 2.0
	var is_left: bool = true
	if node:
		is_left = node.global_position.x < coffin_center_x

	if _tooltip_tween:
		_tooltip_tween.kill()

	# 하단 고정: y=900~1080, 가로는 관 기준 좌/우 (왼쪽 210~900, 오른쪽 1230~1920)
	if is_left:
		_tooltip.offset_left = 210.0
		_tooltip.offset_right = 210.0 + bar_width
		_tooltip.offset_top = bar_top
		_tooltip.offset_bottom = bar_bottom
	else:
		_tooltip.offset_left = viewport_width - bar_width - 10.0
		_tooltip.offset_right = viewport_width - 10.0
		_tooltip.offset_top = bar_top
		_tooltip.offset_bottom = bar_bottom

	_tooltip.z_index = 200
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.color = Color(0.05, 0, 0, 1.0)  # 완전 불투명 배경
	_tooltip.modulate = Color(1, 1, 1, 1)
	_tooltip.visible = true

func hide_tooltip() -> void:
	if _tooltip_tween:
		_tooltip_tween.kill()
		_tooltip_tween = null
	_tooltip.visible = false

func _hide_tooltip() -> void:
	if _tooltip_node and is_instance_valid(_tooltip_node):
		_tooltip_node.queue_free()
	_tooltip_node = null

func show_node_info(node: Node) -> void:
	if _node_info_panel and is_instance_valid(_node_info_panel):
		_node_info_panel.queue_free()
		_node_info_panel = null

	var canvas_layer = $CanvasLayer
	var panel = PanelContainer.new()
	panel.z_index = 200
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var node_screen_pos = node.get_global_transform_with_canvas().origin
	var viewport_size = get_viewport_rect().size
	var panel_x = node_screen_pos.x + 40
	var panel_y = node_screen_pos.y - 60
	panel_x = clampf(panel_x, 10.0, viewport_size.x - 230.0)
	panel_y = clampf(panel_y, 10.0, viewport_size.y - 200.0)
	panel.position = Vector2(panel_x, panel_y)
	panel.custom_minimum_size = Vector2(220, 0)

	var node_color: Color = node.node_color if node.get("node_color") else Color(0.6, 0.1, 0.1, 1.0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.0, 0.01, 0.95)
	style.border_color = node_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var name_label = Label.new()
	name_label.text = node.node_type if node.get("node_type") else node.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = node_color
	vbox.add_child(name_label)

	var sep = HSeparator.new()
	sep.modulate = Color(0.4, 0.1, 0.1, 1.0)
	vbox.add_child(sep)

	var stats = _build_node_stats(node)
	for stat in stats:
		var row = Label.new()
		row.text = stat
		row.add_theme_font_size_override("font_size", 13)
		row.modulate = Color(0.85, 0.85, 0.85, 1.0)
		vbox.add_child(row)

	if node.get("upgrade_level") != null:
		var sep2 = HSeparator.new()
		sep2.modulate = Color(0.4, 0.1, 0.1, 1.0)
		vbox.add_child(sep2)
		var lv_label = Label.new()
		lv_label.text = "Lv." + str(node.upgrade_level + 1)
		lv_label.add_theme_font_size_override("font_size", 12)
		lv_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		vbox.add_child(lv_label)

	canvas_layer.add_child(panel)
	_node_info_panel = panel

	panel.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)

func _build_node_stats(node: Node) -> Array:
	var stats: Array = []
	var type = node.get("node_type")

	match type:
		"흡혈":
			var diff: int = ResourceManager.difficulty if ResourceManager else 0
			var base: float = node.base_damage if node.get("base_damage") else 25.0
			var dmg: float = base + diff * 10.0
			stats.append("⚔ 데미지: " + str(int(dmg)))
			stats.append("📏 범위: 200px")
			var cd: float = node._get_effective_cooldown() if node.has_method("_get_effective_cooldown") else (node.attack_cooldown if node.get("attack_cooldown") else 2.0)
			stats.append("⏱ 쿨다운: %.1f초" % cd)
		"결계":
			stats.append("🔵 감속: 50%")
			stats.append("📏 범위: 200px")
			stats.append("⏱ 지속: 3.0초")
			stats.append("⏱ 쿨다운: %.1f초" % (node.attack_cooldown if node.get("attack_cooldown") else 4.0))
		"증폭":
			stats.append("⚡ 쿨다운 감소: 30%")
			stats.append("📏 범위: 120px")
			stats.append("⏱ 쿨다운: %.1f초" % (node.attack_cooldown if node.get("attack_cooldown") else 2.0))
		_:
			if node.get("base_damage") and node.base_damage > 0:
				stats.append("⚔ 데미지: " + str(int(node.base_damage)))
			if node.get("base_range"):
				stats.append("📏 범위: " + str(node.base_range) + "px")
			elif node.has_method("_get_ability_range"):
				stats.append("📏 범위: " + str(int(node._get_ability_range())) + "px")
			if node.get("base_cooldown"):
				stats.append("⏱ 쿨다운: " + str(node.base_cooldown) + "초")
			elif node.get("attack_cooldown"):
				stats.append("⏱ 쿨다운: %.1f초" % node.attack_cooldown)

	if node.get("_buff_damage_mult") and node._buff_damage_mult > 1.0:
		stats.append("🔥 데미지 버프 활성 중")
	if node.get("_buff_cooldown_mult") and node._buff_cooldown_mult < 1.0:
		stats.append("⚡ 쿨다운 버프 활성 중")

	return stats

func _close_node_info_panel() -> void:
	if not _node_info_panel or not is_instance_valid(_node_info_panel):
		return
	var panel_ref = _node_info_panel
	_node_info_panel = null
	var tw = create_tween()
	tw.tween_property(panel_ref, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func():
		if is_instance_valid(panel_ref):
			panel_ref.queue_free()
	)

func _show_tooltip(data: Dictionary, anchor_pos: Vector2) -> void:
	_hide_tooltip()

	var canvas_layer = $CanvasLayer
	var box = PanelContainer.new()
	box.z_index = 200
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.0, 0.02, 0.92)
	style.border_color = Color(0.6, 0.1, 0.15, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	box.add_child(vbox)

	var title = Label.new()
	title.text = data["title"]
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.85, 0.85, 1.0)
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.modulate = Color(0.5, 0.1, 0.1, 1.0)
	vbox.add_child(sep)

	var desc = Label.new()
	desc.text = data["desc"]
	desc.add_theme_font_size_override("font_size", 16)
	desc.modulate = Color(0.8, 0.8, 0.8, 1.0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(300, 0)
	vbox.add_child(desc)

	for detail in data["details"]:
		var row = Label.new()
		row.text = "• " + detail
		row.add_theme_font_size_override("font_size", 15)
		row.modulate = Color(0.75, 0.75, 0.75, 1.0)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.custom_minimum_size = Vector2(300, 0)
		vbox.add_child(row)

	canvas_layer.add_child(box)
	_tooltip_node = box

	await get_tree().process_frame
	if not is_instance_valid(box):
		return
	var tsize = box.size
	# Q탭 우측 라인(LeftPanel 열림 시 x=40, 너비 220 → 우측 260)에 쫙 붙임
	var left_panel = $CanvasLayer/LeftPanel
	var panel_right: float = 260.0
	if left_panel:
		var panel_rect = left_panel.get_global_rect()
		panel_right = panel_rect.position.x + panel_rect.size.x
	var tx = max(panel_right, 10.0)
	if tx + tsize.x > 1920.0 - 10.0:
		tx = 1920.0 - tsize.x - 10.0
	var ty = clamp(anchor_pos.y - tsize.y - 8.0, 10.0, 1080.0 - tsize.y - 10.0)
	box.position = Vector2(tx, ty)

	box.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)

func _on_blood_row_mouse_entered() -> void:
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/BloodRow
	var rect = row.get_global_rect()
	var anchor = rect.position + Vector2(rect.size.x / 2, rect.size.y)
	_show_tooltip(TOOLTIP_BLOOD, anchor)

func _on_ruby_row_mouse_entered() -> void:
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/RubyRow
	var rect = row.get_global_rect()
	var anchor = rect.position + Vector2(rect.size.x / 2, rect.size.y)
	_show_tooltip(TOOLTIP_RUBY, anchor)

func _on_chip_row_mouse_entered() -> void:
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow
	var rect = row.get_global_rect()
	var anchor = rect.position + Vector2(rect.size.x / 2, rect.size.y)
	_show_tooltip(TOOLTIP_CHIP, anchor)

func _on_ring_light_card_mouse_entered() -> void:
	var card: Control = $CanvasLayer/LeftPanel.get_node_or_null("RingLightCard")
	if card:
		var rect = card.get_global_rect()
		var anchor = rect.position + Vector2(rect.size.x / 2, rect.size.y)
		_show_tooltip(TOOLTIP_RINGLIGHT, anchor)

func _on_rubina_tap_card_mouse_entered() -> void:
	var card: Control = $CanvasLayer/LeftPanel.get_node_or_null("Card2_Automation")
	if card:
		var rect = card.get_global_rect()
		var anchor = rect.position + Vector2(rect.size.x / 2, rect.size.y)
		_show_tooltip(TOOLTIP_RUBINA_TAP, anchor)

func _on_resource_tooltip_exited() -> void:
	_hide_tooltip()

func get_coffin_hp_ratio() -> float:
	return float(coffin_hp) / float(coffin_max_hp) if coffin_max_hp > 0 else 1.0

func _spawn_start_nodes() -> void:
	# 기본 노드: 흡혈 1개, 결계 1개 배치
	var node_scene = preload("res://scenes/GameNode.tscn")
	var grid = $EntityLayer/HeartPulse
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

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
		node.is_starter_node = true
		var offset_x: float = -120.0 if i == 0 else 120.0
		var pos: Vector2 = Vector2(coffin_center.x + offset_x, coffin_center.y)
		node.global_position = pos
		node._slot_position = pos
		var cell: Vector2i = grid.world_to_grid(pos)
		if grid.is_valid_cell(cell.x, cell.y) and grid.is_cell_empty(cell.x, cell.y):
			grid.place_node(cell.x, cell.y, node.node_id)
			node.is_placed = true
			node.grid_col = cell.x
			node.grid_row = cell.y
			node._orbit_shown = true
		$EntityLayer.add_child(node)

func _build_hint_dots() -> void:
	# 기존 자식 전부 제거
	for child in _dots_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var slot_size: int = 64
	var spacing: int = 88
	var total_width: int = 6 * spacing
	var start_x: int = (1920 - total_width) / 2

	for i in range(6):
		var slot: Panel = Panel.new()
		slot.name = "Slot%d" % i
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.size = Vector2(slot_size, slot_size)
		slot.position = Vector2(start_x + i * spacing, 18)

		# 빈 슬롯 스타일
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
		style.set_corner_radius_all(32)
		style.border_color = Color(0.4, 0.1, 0.1, 0.6)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		slot.add_theme_stylebox_override("panel", style)
		slot.modulate.a = 0.0

		_dots_container.add_child(slot)

	# BloodCounter (HintArea와 무관하게 항상 표시 → CanvasLayer 직속)
	print("BloodCounter 생성 / 기존 개수: ", $CanvasLayer.get_children().filter(
		func(c): return c.name == "BloodCounter"
	).size())
	var existing = $CanvasLayer.get_node_or_null("BloodCounter")
	if existing:
		existing.queue_free()
		await get_tree().process_frame
	var blood_counter: Label = Label.new()
	blood_counter.name = "BloodCounter"
	blood_counter.add_theme_font_size_override("font_size", 24)
	blood_counter.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4, 0.85))
	blood_counter.size = Vector2(160, 40)
	blood_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blood_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	blood_counter.position = Vector2(1920 / 2 - 80, 895)
	blood_counter.visible = true
	blood_counter.text = "🩸 %d" % ResourceManager.blood
	$CanvasLayer.add_child(blood_counter)
	_blood_counter_ref = blood_counter
	_displayed_blood = ResourceManager.blood

	for i in range(6):
		if i < _slot_data.size():
			_update_slot_visual(i)

	_setup_slot_inputs()

func _setup_slot_inputs() -> void:
	var slots = _dots_container.get_children()
	for i in range(min(6, slots.size())):
		var slot = slots[i]
		if not slot is Panel:
			continue
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx: int = i
		if idx >= _unlocked_slots:
			slot.gui_input.connect(_on_unlock_slot_gui_input)
		else:
			slot.gui_input.connect(func(ev): _on_slot_clicked(ev, idx))

func _on_slot_clicked(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var node_id = _slot_data[index] if index < _slot_data.size() else ""
	if node_id == "":
		get_viewport().set_input_as_handled()
		return
	var total_nodes: int = get_tree().get_nodes_in_group("game_nodes").size()
	if total_nodes >= _unlocked_slots:
		_shake_slot(index)
		_show_deny_popup("↓ 아래에서 슬롯을 해금하세요")
		_show_slot_full_guide()
		return
	for d in _owned_nodes:
		if d["id"] == node_id:
			_spawn_node_to_field(d, false)  # spend_on_drop=false (이미 소유)
			_slot_data[index] = ""
			_update_slot_visual(index)
			break

func _play_orbit_effect_at_pos(pos: Vector2, color: Color) -> void:
	var effect = Node2D.new()
	effect.set_script(preload("res://scripts/SlotUnlockEffect.gd"))
	effect.position = pos
	effect.orbit_color = color
	$EntityLayer.add_child(effect)

func _highlight_slot(index: int, on: bool) -> void:
	var slots = _dots_container.get_children()
	if index >= slots.size():
		return
	var slot = slots[index]
	if not slot is Panel:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	if on:
		style.bg_color = Color(0.3, 0.1, 0.1, 0.9)
		style.border_color = Color(1.0, 0.3, 0.3, 1.0)
	else:
		var node_id = _slot_data[index] if index < _slot_data.size() else ""
		var node_data = null
		if node_id != "":
			for d in _owned_nodes:
				if d["id"] == node_id:
					node_data = d
					break
		if node_data:
			style.bg_color = Color(
				node_data["color"].r * 0.2,
				node_data["color"].g * 0.2,
				node_data["color"].b * 0.2, 0.9)
			style.border_color = node_data["color"]
		else:
			style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
			style.border_color = Color(0.4, 0.1, 0.1, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	slot.add_theme_stylebox_override("panel", style)

const PLACEMENT_VALID_RANGE: float = 300.0  # 관/링라이트 유효 배치 반경 (RingLight.RANGE_RADIUS와 동일)

func _is_valid_node_placement(pos: Vector2) -> bool:
	# 1. 관 중심 기준 범위 체크
	var coffin = get_tree().get_first_node_in_group("coffin")
	if coffin:
		var coffin_center: Vector2 = coffin.global_position + coffin.size / 2.0
		var dist: float = pos.distance_to(coffin_center)
		if dist <= PLACEMENT_VALID_RANGE:
			return true
	# 2. 링라이트 범위 체크
	var lights = get_tree().get_nodes_in_group("ring_light")
	for light in lights:
		var dist: float = pos.distance_to(light.global_position)
		if ("is_placed" in light and light.is_placed):
			var r: float = light.range_radius if "range_radius" in light else PLACEMENT_VALID_RANGE
			if dist <= r:
				return true
	return false

func remove_game_node(node: Node2D) -> void:
	if "grid_col" in node and "grid_row" in node:
		var col: int = node.grid_col
		var row: int = node.grid_row
		if col >= 0 and row >= 0:
			var grid = get_tree().get_first_node_in_group("heart_pulse")
			if grid and grid.has_method("remove_node"):
				grid.remove_node(col, row)
	if node in _selected_nodes:
		_selected_nodes.erase(node)
	_update_slot_count_label()

func _get_slot_at(pos: Vector2) -> int:
	var slots = _dots_container.get_children()
	for i in range(min(6, slots.size())):
		var slot = slots[i]
		if not slot is Panel:
			continue
		var slot_rect: Rect2 = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(pos):
			return i
	return -1

func _register_to_slot(index: int, node: Node2D) -> void:
	for i in range(_slot_data.size()):
		if _slot_data[i] == node.node_id:
			_slot_data[i] = ""
			_update_slot_visual(i)
	_slot_data[index] = node.node_id
	_update_slot_visual(index)
	# 필드에서 노드 제거 (데이터는 _owned_nodes에 보관)
	var node_data = {"id": node.node_id, "type": node.node_type, "color": node.node_color}
	var exists = false
	for d in _owned_nodes:
		if d["id"] == node.node_id:
			exists = true
			break
	if not exists:
		_owned_nodes.append(node_data)
	node.queue_free()
	call_deferred("_update_slot_count_label")

func _update_slot_visual(index: int) -> void:
	var slots = _dots_container.get_children()
	if index >= slots.size():
		return
	var slot = slots[index]
	if not slot is Panel:
		return
	for child in slot.get_children():
		slot.remove_child(child)
		child.free()
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	var is_locked: bool = index >= _unlocked_slots
	var node_id = _slot_data[index]
	var node_data = null
	if node_id != "":
		for d in _owned_nodes:
			if d["id"] == node_id:
				node_data = d
				break
	if is_locked:
		# 잠금 슬롯: 자물쇠 아이콘 + 해금 비용
		style.bg_color = Color(0.02, 0.0, 0.0, 0.85)
		style.border_color = Color(0.5, 0.15, 0.15, 0.8)
		slot.add_theme_stylebox_override("panel", style)
		var lock_label: Label = Label.new()
		lock_label.text = "🔒\n🩸%d" % _get_slot_unlock_cost()
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 11)
		lock_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 0.9))
		lock_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_label.offset_left = 4
		lock_label.offset_top = 4
		lock_label.offset_right = -4
		lock_label.offset_bottom = -4
		slot.add_child(lock_label)
	elif node_data:
		style.bg_color = Color(
			node_data["color"].r * 0.15,
			node_data["color"].g * 0.15,
			node_data["color"].b * 0.15, 0.9)
		style.border_color = node_data["color"]
		slot.add_theme_stylebox_override("panel", style)
		slot.clip_contents = true

		var node_scene = preload("res://scenes/GameNode.tscn")
		var preview = node_scene.instantiate()
		preview.node_id = node_data["id"]
		preview.node_type = node_data["type"]
		preview.node_color = node_data["color"]
		preview.scale = Vector2(0.55, 0.55)
		preview.position = Vector2(32, 32)
		preview.set_process(false)
		preview.set_physics_process(false)
		preview.set_process_input(false)
		preview.is_preview = true
		slot.add_child(preview)
	else:
		# 해금된 빈 슬롯
		style.bg_color = Color(0.05, 0.0, 0.0, 0.7)
		style.border_color = Color(0.4, 0.1, 0.1, 0.6)
		slot.add_theme_stylebox_override("panel", style)

func _build_owned_nodes() -> void:
	# 1. 기존 자식 전부 제거
	for child in _owned_container.get_children():
		child.queue_free()
	# 2. 한 프레임 대기 (queue_free 완료)
	await get_tree().process_frame

	# 3. _owned_nodes 루프 (흡혈/결계/증폭 버튼)
	for data in _owned_nodes:
		var row: Button = Button.new()
		row.custom_minimum_size = Vector2(190, 52)
		row.text = ""
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(
			data.color.r * 0.2,
			data.color.g * 0.2,
			data.color.b * 0.2, 0.9)
		style.set_corner_radius_all(8)
		style.border_color = Color(
			data.color.r, data.color.g, data.color.b, 0.6)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		row.add_theme_stylebox_override("normal", style)
		var name_label: Label = Label.new()
		name_label.text = data.type
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0, 0.9))
		name_label.position = Vector2(12, 8)
		row.add_child(name_label)
		var cost_label: Label = Label.new()
		match data.id:
			"absorb": cost_label.text = "🩸 10"
			"freeze": cost_label.text = "🩸 15"
			"resonate": cost_label.text = "🩸 20"
			_: cost_label.text = "🩸 0"
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color",
			Color(1.0, 0.5, 0.5, 0.8))
		cost_label.position = Vector2(12, 28)
		row.add_child(cost_label)
		row.gui_input.connect(func(ev): _on_owned_node_input(ev, data))
		_owned_container.add_child(row)

	# 링라이트 버튼 (RingLightCard에 배치 — OwnedNodesContainer 바로 위)
	var ring_card = $CanvasLayer/LeftPanel.get_node_or_null("RingLightCard")
	if ring_card:
		for child in ring_card.get_children():
			child.queue_free()
		await get_tree().process_frame

	var installed = 0
	for l in get_tree().get_nodes_in_group("ring_light"):
		if "is_placed" in l and l.is_placed:
			installed += 1

	var ring_btn = Button.new()
	ring_btn.custom_minimum_size = Vector2(190, 52)
	ring_btn.text = "링라이트  🔴2\n설치 %d / 3" % installed

	var ring_style = StyleBoxFlat.new()
	ring_style.bg_color = Color(0.15, 0.12, 0.05, 1.0)
	ring_style.border_color = Color(1.0, 0.9, 0.5, 0.8)
	ring_style.set_border_width_all(1)
	ring_btn.add_theme_stylebox_override("normal", ring_style)

	if installed >= 3:
		ring_btn.disabled = true

	ring_btn.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and \
		   ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_spawn_ring_light()
	)
	if ring_card:
		ring_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		ring_btn.offset_left = 4
		ring_btn.offset_top = 4
		ring_btn.offset_right = -4
		ring_btn.offset_bottom = -4
		ring_card.add_child(ring_btn)
		ring_btn.mouse_entered.connect(_on_ring_light_card_mouse_entered)
		ring_btn.mouse_exited.connect(_on_resource_tooltip_exited)
	else:
		_owned_container.add_child(ring_btn)

	# 4. 빈 슬롯 3개 (클릭해도 아무 동작 안함)
	for _i in range(3):
		var empty = Panel.new()
		empty.custom_minimum_size = Vector2(190, 52)
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.08, 0.0, 0.0)
		empty_style.border_color = Color(0.4, 0.0, 0.0)
		empty_style.set_border_width_all(1)
		empty.add_theme_stylebox_override("panel", empty_style)
		var empty_label = Label.new()
		empty_label.text = "비어있음"
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.0, 0.0))
		empty_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		empty.add_child(empty_label)
		empty.gui_input.connect(func(ev): _on_empty_owned_slot_input(ev))
		_owned_container.add_child(empty)

	$CanvasLayer/LeftPanel/Card4_DeckSlots.hide()

func _get_node_cost(data: Dictionary) -> int:
	if data.has("cost"):
		return data["cost"]
	match data.get("id", ""):
		"absorb": return 10
		"freeze": return 15
		"resonate": return 20
	return 0

func _spawn_node_to_field(data: Dictionary, spend_on_drop: bool = false) -> Node2D:
	var node_scene = preload("res://scenes/GameNode.tscn")
	var node = node_scene.instantiate()
	node.node_id = data.id
	node.node_type = data.type
	node.node_color = data.color
	node.spawn_cost = _get_node_cost(data) if spend_on_drop else 0
	node.global_position = get_viewport().get_mouse_position()
	node._slot_position = get_viewport().get_mouse_position()
	node.is_dragging = true
	node._drag_offset = Vector2.ZERO
	node._drag_start_pos = get_viewport().get_mouse_position()
	$EntityLayer.add_child(node)
	call_deferred("_update_slot_count_label")
	return node

func _on_owned_node_input(event: InputEvent, data: Dictionary) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var cost: int = _get_node_cost(data)
	if ResourceManager.blood < cost:
		_show_deny_popup("혈액 부족! 🩸%d 필요" % cost)
		return

	var same_count: int = 0
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.node_type == data.type:
			same_count += 1
	if same_count >= 2:
		_show_deny_popup("%s 노드는 최대 2개까지!" % data.type)
		return

	var total_nodes: int = get_tree().get_nodes_in_group("game_nodes").size()
	if total_nodes >= _unlocked_slots:
		_show_deny_popup("↓ 아래에서 슬롯을 해금하세요")
		_show_slot_full_guide()
		return

	_spawn_node_to_field(data, true)  # spend_on_drop=true

func register_node_select(node: Node2D) -> void:
	if node in _selected_nodes:
		_selected_nodes.erase(node)
		node.is_selected = false
		_sync_connection_manager_selected()
		return

	if _selected_nodes.size() >= 3:
		var oldest = _selected_nodes[0]
		if is_instance_valid(oldest) and oldest.has_method("start_range_fade_out"):
			oldest.start_range_fade_out()
		_selected_nodes.pop_front()

	_selected_nodes.append(node)
	node.is_selected = true
	_sync_connection_manager_selected()

func clear_all_node_selection() -> void:
	for n in _selected_nodes:
		if is_instance_valid(n):
			n.is_selected = false
			if n.has_method("_cancel_range_fade"):
				n._cancel_range_fade()
	_selected_nodes.clear()
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm and cm.has_method("clear_selected"):
		cm.clear_selected()

func _sync_connection_manager_selected() -> void:
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm and cm.has_method("set_selected"):
		if _selected_nodes.is_empty():
			cm.clear_selected()
		else:
			cm.set_selected(_selected_nodes[-1])

func _on_empty_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_show_deny_popup("상점에서 노드를 구매해 채워넣으세요!")

func _on_empty_owned_slot_input(event: InputEvent) -> void:
	# Q패널 빈 슬롯 클릭 시 이벤트만 흡수 (활성화 방지)
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()

func _make_slot_input_handler(index: int) -> Callable:
	return func(event: InputEvent): _on_slot_gui_input(event, index)

func _spawn_guide_arrow(canvas_layer: Node) -> void:
	var arrow_node = Node2D.new()
	arrow_node.z_index = 100
	arrow_node.position = Vector2(960, 820)
	arrow_node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	canvas_layer.add_child(arrow_node)

	var shaft = Line2D.new()
	shaft.width = 16.0
	shaft.default_color = Color(1.0, 0.92, 0.1, 1.0)
	shaft.add_point(Vector2(0, -55))
	shaft.add_point(Vector2(0, 20))
	arrow_node.add_child(shaft)

	var head = Polygon2D.new()
	head.color = Color(1.0, 0.92, 0.1, 1.0)
	head.polygon = PackedVector2Array([
		Vector2(-28, 18),
		Vector2(28, 18),
		Vector2(0, 70)
	])
	arrow_node.add_child(head)

	var glow_shaft = Line2D.new()
	glow_shaft.width = 28.0
	glow_shaft.default_color = Color(1.0, 0.92, 0.1, 0.25)
	glow_shaft.add_point(Vector2(0, -55))
	glow_shaft.add_point(Vector2(0, 20))
	arrow_node.add_child(glow_shaft)

	var glow_head = Polygon2D.new()
	glow_head.color = Color(1.0, 0.92, 0.1, 0.25)
	glow_head.polygon = PackedVector2Array([
		Vector2(-38, 15),
		Vector2(38, 15),
		Vector2(0, 85)
	])
	arrow_node.add_child(glow_head)

	var tw = create_tween()
	tw.tween_property(arrow_node, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(arrow_node, "modulate:a", 0.0, 0.18)
	tw.tween_property(arrow_node, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(arrow_node, "modulate:a", 0.0, 0.22)
	var acb = func(): arrow_node.queue_free()
	tw.tween_callback(acb)

func _show_slot_full_guide() -> void:
	var canvas_layer = $CanvasLayer

	# 1. 화살표 (Line2D + Polygon2D)
	_spawn_guide_arrow(canvas_layer)

	# 2. 인디케이터 슬롯 노란 강조 점등
	var hint = _dots_container
	if hint:
		var htw = create_tween()
		htw.tween_property(hint, "modulate", Color(1.5, 1.3, 0.2, 1.0), 0.15).set_ease(Tween.EASE_OUT)
		htw.tween_property(hint, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
		htw.tween_property(hint, "modulate", Color(1.5, 1.3, 0.2, 1.0), 0.15)
		htw.tween_property(hint, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _show_blood_bonus_popup(amount: int) -> void:
	var canvas_layer = $CanvasLayer
	var blood_counter = canvas_layer.get_node_or_null("BloodCounter")
	if not blood_counter:
		return

	var base_pos = blood_counter.get_global_transform_with_canvas().origin

	var bonus_label = Label.new()
	bonus_label.text = "+" + str(amount)
	bonus_label.add_theme_font_size_override("font_size", 20)
	bonus_label.modulate = Color(1.0, 0.85, 0.1, 0.0)
	bonus_label.z_index = 100
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus_label.position = Vector2(
		base_pos.x + blood_counter.size.x + 5,
		base_pos.y)
	canvas_layer.add_child(bonus_label)

	# 순차 tween (parallel 없이)
	var ltw = create_tween()
	# 페이드인 + 위로
	ltw.tween_property(bonus_label, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	ltw.tween_property(bonus_label, "position:y", base_pos.y - 35, 0.4).set_ease(Tween.EASE_OUT)
	# 잠깐 유지
	ltw.tween_interval(0.2)
	# 페이드아웃
	ltw.tween_property(bonus_label, "modulate:a", 0.0, 0.25)
	# 제거
	var lcb = func(): bonus_label.queue_free()
	ltw.tween_callback(lcb)

var _deny_popup_tween: Tween = null

func _show_deny_popup(text: String) -> void:
	var old = $CanvasLayer.get_node_or_null("DenyPopup")
	if old and old is Label:
		# 기존 팝업 재사용 — 텍스트 겹침 방지
		if _deny_popup_tween and _deny_popup_tween.is_valid():
			_deny_popup_tween.kill()
		old.text = text
		old.modulate.a = 1.0
		old.position.y = _coffin_base_pos.y - 80
		old.visible = true
		_deny_popup_tween = old.create_tween()
		_deny_popup_tween.tween_property(old, "position:y", _coffin_base_pos.y - 100, 0.2).set_ease(Tween.EASE_OUT)
		_deny_popup_tween.tween_interval(1.5)
		_deny_popup_tween.tween_property(old, "position:y", _coffin_base_pos.y - 180, 0.3).set_ease(Tween.EASE_IN)
		_deny_popup_tween.tween_property(old, "modulate:a", 0.0, 0.15)
		_deny_popup_tween.tween_callback(old.queue_free)
		_deny_popup_tween.tween_callback(func(): _deny_popup_tween = null)
		return

	var label: Label = Label.new()
	label.name = "DenyPopup"
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(400, 50)
	label.position = Vector2(_coffin_base_pos.x - 200, _coffin_base_pos.y - 80)
	$CanvasLayer.add_child(label)

	_deny_popup_tween = label.create_tween()
	_deny_popup_tween.tween_property(label, "position:y", _coffin_base_pos.y - 100, 0.2).set_ease(Tween.EASE_OUT)
	_deny_popup_tween.tween_interval(1.5)
	_deny_popup_tween.tween_property(label, "position:y", _coffin_base_pos.y - 180, 0.3).set_ease(Tween.EASE_IN)
	_deny_popup_tween.tween_property(label, "modulate:a", 0.0, 0.15)
	_deny_popup_tween.tween_callback(label.queue_free)
	_deny_popup_tween.tween_callback(func(): _deny_popup_tween = null)

func _shake_slot(index: int) -> void:
	var slot = _dots_container.get_child(index)
	var tween: Tween = create_tween()
	var ox: float = slot.position.x
	tween.tween_property(slot, "position:x", ox + 3, 0.03)
	tween.tween_property(slot, "position:x", ox - 3, 0.03)
	tween.tween_property(slot, "position:x", ox + 3, 0.03)
	tween.tween_property(slot, "position:x", ox - 3, 0.03)
	tween.tween_property(slot, "position:x", ox, 0.03)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	# 중복 방지: 이미 이 슬롯으로 처리 중이면 무시
	if _pending_spawn_index == index:
		get_viewport().set_input_as_handled()
		return

	if index >= _unlocked_slots:
		return

	var data = _node_slots[index]

	# 재화 부족
	if ResourceManager.blood < data.cost:
		_shake_slot(index)
		_show_deny_popup("혈액 부족! 🩸%d 필요" % data.cost)
		return

	# 종류별 중복 체크
	var same_type_count: int = 0
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.node_type == data.type:
			same_type_count += 1
	if same_type_count >= 2:
		_shake_slot(index)
		_show_deny_popup("%s 노드는 최대 2개까지!" % data.type)
		return

	# 총 노드 수 초과
	var total_nodes: int = get_tree().get_nodes_in_group("game_nodes").size()
	if total_nodes >= _unlocked_slots:
		_shake_slot(index)
		_show_deny_popup("↓ 아래에서 슬롯을 해금하세요")
		_show_slot_full_guide()
		return

	_pending_spawn_index = index
	_spawn_node_to_field(data, true)  # spend_on_drop=true
	call_deferred("_clear_pending_spawn")  # 프레임 끝에 초기화 (중복 이벤트 방지)
	get_viewport().set_input_as_handled()

func _clear_pending_spawn() -> void:
	_pending_spawn_index = -1

func _on_unlock_slot_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	get_viewport().set_input_as_handled()
	_unlock_next_slot()

func _get_slot_unlock_cost() -> int:
	if _unlocked_slots >= 6:
		return 0
	var idx: int = _unlocked_slots - 3
	if idx >= 0 and idx < _slot_unlock_costs.size():
		return int(_slot_unlock_costs[idx])
	return 0

func _unlock_next_slot() -> void:
	if _unlock_in_progress:
		return
	var cost: int = _get_slot_unlock_cost()
	if cost <= 0:
		return
	if ResourceManager.blood < cost:
		var slot = _dots_container.get_child(_unlocked_slots)
		var ox: float = slot.position.x
		var tween: Tween = create_tween()
		tween.tween_property(slot, "position:x", ox + 3, 0.03)
		tween.tween_property(slot, "position:x", ox - 3, 0.03)
		tween.tween_property(slot, "position:x", ox + 3, 0.03)
		tween.tween_property(slot, "position:x", ox - 3, 0.03)
		tween.tween_property(slot, "position:x", ox, 0.03)
		return

	_unlock_in_progress = true
	ResourceManager.spend_blood(cost)
	_unlocked_slots += 1

	_hint_hiding = false
	for t in _hint_hide_tweens:
		if t and is_instance_valid(t):
			t.kill()
	_hint_hide_tweens.clear()
	await _build_hint_dots()

	# 해금 애니메이션 동안 인디케이터 숨기지 않음
	_unlock_animation_playing = true

	# 해금 이펙트
	var new_slot = _dots_container.get_child(_unlocked_slots - 1)

	# 1. 시작: 작게 + 투명
	new_slot.scale = Vector2(0.3, 0.3)
	new_slot.modulate.a = 0.0
	new_slot.pivot_offset = Vector2(32, 32)

	# 2. 펑 하고 커졌다가 제자리
	var tween: Tween = create_tween()
	tween.tween_property(new_slot, "scale", Vector2(1.3, 1.3), 0.2
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(new_slot, "modulate:a", 1.0, 0.15)
	tween.tween_property(new_slot, "scale", Vector2(1.0, 1.0), 0.15
		).set_ease(Tween.EASE_IN_OUT)

	# 3. 슬롯 해금 이펙트: 은은한 파동 1번
	var slot_idx: int = _unlocked_slots - 1
	var slot = _dots_container.get_children()[slot_idx]
	var hint_area_y: float = _hint_area.position.y
	var slot_x: float = slot.position.x + slot.size.x / 2
	var slot_y: float = hint_area_y + slot.position.y + slot.size.y / 2

	var effect: Node2D = Node2D.new()
	effect.global_position = Vector2(slot_x, slot_y)
	$EntityLayer.add_child(effect)

	var ring: Panel = Panel.new()
	ring.size = Vector2(56, 56)
	ring.position = Vector2(-28, -28)
	ring.pivot_offset = Vector2(28, 28)
	ring.modulate.a = 0.0
	var ring_style: StyleBoxFlat = StyleBoxFlat.new()
	ring_style.set_corner_radius_all(28)
	ring_style.bg_color = Color(0.8, 0.2, 0.2, 0.12)
	ring_style.border_color = Color(0.9, 0.35, 0.35, 0.5)
	ring_style.set_border_width_all(2)
	ring.add_theme_stylebox_override("panel", ring_style)
	effect.add_child(ring)

	var tw: Tween = ring.create_tween()
	tw.tween_property(ring, "modulate:a", 1.0, 0.05)
	tw.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.35).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.25).set_delay(0.06).set_ease(Tween.EASE_IN)
	tw.tween_callback(effect.queue_free)

	await get_tree().create_timer(0.45).timeout
	_unlock_animation_playing = false
	_unlock_in_progress = false
	_update_slot_count_label()

func _get_chat_manager() -> Node:
	return get_tree().get_first_node_in_group("chat_manager")

func _has_synergy_connection() -> bool:
	var cm = get_tree().get_first_node_in_group("connection_manager")
	if cm:
		return cm._connections.size() > 0
	return false

func _init_viewers() -> void:
	var base: int = 50 + ResourceManager.total_runs * 30
	_viewers = randi_range(base, base + 50)
	var like_base: int = 10 + ResourceManager.total_runs * 10
	_likes = randi_range(like_base, like_base + 20)
	var cm = _get_chat_manager()
	if cm and cm.has_method("set_idle_interval_range"):
		if _viewers < 100:
			cm.set_idle_interval_range(4.0, 7.0)
		elif _viewers < 300:
			cm.set_idle_interval_range(2.5, 5.0)
		else:
			cm.set_idle_interval_range(1.5, 3.0)
	_update_viewer_ui()

func update_ruby_ui(amount: int) -> void:
	if _left_ruby_label:
		_left_ruby_label.text = str(amount)

func _show_ruby_popup(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(860, 160)
	$CanvasLayer.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", 140.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

func _update_viewer_ui() -> void:
	if _viewers > ResourceManager.best_viewers:
		ResourceManager.best_viewers = _viewers
	if _viewer_label:
		_viewer_label.text = "👁 %d" % _viewers
	if _like_label:
		_like_label.text = "❤ %d" % _likes

func on_difficulty_up() -> void:
	_viewers += randi_range(20, 80)
	_likes += randi_range(5, 20)
	_update_viewer_ui()
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("danger")

func _get_hovered_game_node():
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.is_hovered:
			return n
	return null

func on_entity_killed() -> void:
	_combo_count += 1
	_combo_timer = _combo_duration
	_kill_count += 1

	var cm = _get_chat_manager()
	if cm:
		if _combo_count >= 3:
			cm.send_chat("combo")
		elif _combo_count >= 1:
			cm.send_chat("kill")
	if _combo_count >= 3:
		_likes += randi_range(3, 10)
		_update_viewer_ui()
	if _combo_count == 5:
		ResourceManager.add_ruby(1)
		_show_ruby_popup("5콤보 달성! 🔴+1")

	# 콤보 배수 계산
	var multiplier: float = 1.0
	if _combo_count >= 5:
		multiplier = 2.0
	elif _combo_count >= 3:
		multiplier = 1.5

	# 콤보 텍스트 표시
	if _combo_count >= 3:
		_show_combo_popup(_combo_count, multiplier)

func reset_combo() -> void:
	_combo_count = 0
	_combo_timer = 0.0

func trigger_hitstop(duration: float = 0.06) -> void:
	_hitstop_timer = duration

func _show_combo_popup(count: int, multiplier: float) -> void:
	var label: Label = Label.new()
	if count >= 5:
		label.text = "%d KILL  x%.0f 재화!" % [count, multiplier]
		label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0, 1.0))
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.text = "%d KILL  x%.1f" % [count, multiplier]
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
		label.add_theme_font_size_override("font_size", 22)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 50)
	label.position = Vector2(810, 210)  # 시너지 팝업(50-120) 아래에 배치
	$CanvasLayer.add_child(label)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", 190.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)

func _process(delta: float) -> void:
	_last_delta = delta
	if _hitstop_timer > 0:
		_hitstop_timer -= delta / Engine.time_scale  # 실제 시간 기준 감소
		Engine.time_scale = 0.05
		return
	else:
		Engine.time_scale = 1.0

	if _is_game_over:
		_apply_shake(delta)
		return
	if _coffin_barrier_active:
		_check_coffin_barrier()
	if _combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_combo_count = 0
	_elapsed_time += delta
	_remaining_time -= delta
	var difficulty: int = int(_elapsed_time / 30.0)
	spawn_interval = max(1.5, 4.0 - difficulty * 0.35)
	max_entities = min(10, 4 + difficulty)
	if ResourceManager:
		ResourceManager.difficulty = difficulty
	if difficulty != _prev_difficulty:
		_prev_difficulty = difficulty
		on_difficulty_up()

	_viewer_timer += delta
	_like_timer += delta
	if _viewer_timer >= 5.0:
		_viewer_timer = 0.0
		var change: int = randi_range(-5, 15)
		_viewers = max(1, _viewers + change)
		_update_viewer_ui()
	if _like_timer >= 8.0:
		_like_timer = 0.0
		var like_change: int = randi_range(0, 5)
		_likes += like_change
		_update_viewer_ui()

	var hp_ratio: float = coffin_hp / coffin_max_hp
	if hp_ratio <= 0.1 and not _danger_chat_sent:
		_danger_chat_sent = true
		var cm = _get_chat_manager()
		if cm:
			cm.send_chat("danger")
	elif hp_ratio > 0.1:
		_danger_chat_sent = false

	if coffin_hp >= coffin_max_hp:
		_no_hit_timer += delta
		if _no_hit_timer >= 30.0 and not _perfect_defense_notified:
			_perfect_defense_notified = true
			_no_hit_timer = 0.0
			ResourceManager.add_ruby(1)
			_show_ruby_popup("퍼펙트 디펜스! 🔴+1")
	else:
		_no_hit_timer = 0.0
		_perfect_defense_notified = false

	if _elapsed_time >= 20.0 and not _ai_chat_started:
		_ai_chat_started = true
		var cm = _get_chat_manager()
		if cm:
			cm._ai_chat_enabled = true

	_state_timer += delta
	if _state_timer >= 2.0:
		_state_timer = 0.0
		var cm = _get_chat_manager()
		if cm:
			cm.update_game_state({
				"hp_ratio": coffin_hp / coffin_max_hp,
				"difficulty": difficulty,
				"blood": ResourceManager.blood,
				"placed_nodes": get_tree().get_nodes_in_group("game_nodes").size(),
				"connected": _has_synergy_connection(),
				"combo": _combo_count,
				"time_left": _remaining_time
			})

	var minutes: int = int(_remaining_time) / 60
	var seconds: int = int(_remaining_time) % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]

	# 30초 이하 빨갛게 깜빡임
	if _remaining_time <= 30.0:
		var blink: float = abs(sin(_elapsed_time * 4.0))
		_timer_label.add_theme_color_override("font_color",
			Color(1.0, blink * 0.3, blink * 0.3, 1.0))
	else:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	# 시간 종료
	if _remaining_time <= 0.0:
		_remaining_time = 0.0
		_timer_label.text = "00:00"
		_escape_success()

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
	_update_coffin_visual()

	if _hp_visible:
		_hp_hide_timer -= delta
		if _hp_hide_timer <= 0.0:
			_hp_visible = false
			_fade_hp_bar(false)

	var my: float = get_viewport().get_mouse_position().y
	if _slots_in_panel:
		pass  # 슬롯이 Q 패널에 있으면 하단 바 표시 안 함
	elif my > 820:
		# 숨기기 진행 중에 마우스 다시 내리면 즉시 취소 후 표시
		if _hint_hiding:
			_hint_hiding = false
			for t in _hint_hide_tweens:
				if t and is_instance_valid(t):
					t.kill()
			_hint_hide_tweens.clear()
			var dots: Array = _dots_container.get_children()
			for dot in dots:
				if dot.name == "BloodBG":
					dot.modulate = Color(1, 1, 1, 1)
				else:
					dot.position = Vector2(dot.position.x, 30.0)
					dot.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 950.0)
		elif not _hint_area.visible:
			_hint_area.visible = true
			_hint_area.modulate = Color(1, 1, 1, 1)
			_hint_area.position = Vector2(_hint_area.position.x, 1020.0)
			if _indicator_was_hidden:
				_indicator_was_hidden = false
				for i in range(_slot_data.size()):
					_update_slot_visual(i)

			var area_tween: Tween = _hint_area.create_tween()
			area_tween.tween_property(_hint_area, "position:y", 950.0, 0.35
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

			var dots = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				if dot.name == "BloodBG":
					dot.modulate = Color(1, 1, 1, 0)
					var tween: Tween = dot.create_tween()
					tween.tween_interval(0.1)
					tween.tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.2)
					continue
				dot.position = Vector2(dot.position.x, 70.0)
				dot.modulate = Color(1, 1, 1, 0)

				var tween: Tween = dot.create_tween()
				tween.tween_interval(i * 0.07)
				tween.tween_property(dot, "position:y", 30.0, 0.35
				).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 1), 0.25)
	else:
		_indicator_was_hidden = true
		if not _slots_in_panel and _hint_area.visible and not _hint_hiding and not _unlock_animation_playing:
			_hint_hiding = true
			_hint_hide_tweens.clear()
			var area_tween: Tween = _hint_area.create_tween()
			_hint_hide_tweens.append(area_tween)
			area_tween.tween_property(_hint_area, "position:y", 1020.0, 0.25
			).set_ease(Tween.EASE_IN)

			var dots: Array = _dots_container.get_children()
			for i in range(dots.size()):
				var dot: Control = dots[i]
				if dot.name == "BloodBG":
					var tween: Tween = dot.create_tween()
					_hint_hide_tweens.append(tween)
					tween.tween_interval(0.12)
					tween.tween_property(dot, "modulate", Color(1, 1, 1, 0), 0.22)
					continue
				var tween: Tween = dot.create_tween()
				_hint_hide_tweens.append(tween)
				tween.tween_interval(i * 0.05)
				tween.tween_property(dot, "position:y", 70.0, 0.25
				).set_ease(Tween.EASE_IN)
				tween.parallel().tween_property(dot, "modulate", Color(1, 1, 1, 0), 0.2)

			var hide_delay: float = dots.size() * 0.05 + 0.25
			get_tree().create_timer(hide_delay).timeout.connect(func():
				if _hint_hiding:
					_hint_area.visible = false
					_hint_hiding = false
					_hint_hide_tweens.clear()
			)

	# BloodCounter는 update_blood_ui()에서 애니메이션으로 갱신 (blood_changed 시그널)

	# 드래그 중인 노드가 인디케이터 슬롯 위에 있는지 감지
	var dragging_node: Node2D = null
	for n in get_tree().get_nodes_in_group("game_nodes"):
		if n.is_dragging:
			dragging_node = n
			break

	if dragging_node and not dragging_node.is_placed:
		var mouse_y: float = get_viewport().get_mouse_position().y
		if mouse_y > 880:
			var slots = _dots_container.get_children()
			for i in range(min(6, slots.size())):
				var slot = slots[i]
				if not slot is Panel:
					continue
				var slot_rect: Rect2 = Rect2(slot.global_position, slot.size)
				if slot_rect.has_point(get_viewport().get_mouse_position()):
					_highlight_slot(i, true)
				else:
					_highlight_slot(i, false)
		else:
			for i in range(6):
				_highlight_slot(i, false)
	else:
		for i in range(6):
			_highlight_slot(i, false)

	# 필드에 배치된 노드만 툴팁 표시
	var hovered_node = _get_hovered_game_node()
	if hovered_node and hovered_node.is_placed:
		show_tooltip(hovered_node._get_node_info(), hovered_node.node_color, hovered_node)
	else:
		hide_tooltip()

	_apply_shake(delta)

func _spawn_blood_entity() -> void:
	var difficulty: int = int(_elapsed_time / 30.0)
	ResourceManager.difficulty = difficulty

	var entity: Node2D
	if difficulty >= 4:
		var stage4_scene = preload("res://scenes/BloodEntityStage4.tscn")
		entity = stage4_scene.instantiate()
		entity._is_evolved = true
		entity._difficulty = difficulty
	else:
		entity = blood_entity_scene.instantiate()

	entity.add_to_group("blood_entities")
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

	var side: int = randi() % 4
	var pos: Vector2
	match side:
		0: pos = Vector2(randf_range(0, 1920), -50)
		1: pos = Vector2(randf_range(0, 1920), 1130)
		2: pos = Vector2(-50, randf_range(0, 1080))
		3: pos = Vector2(1970, randf_range(0, 1080))

	entity.global_position = pos
	entity.target = coffin_center
	entity.radius = 27.0 + difficulty * 2.0
	entity.max_hp = 60.0 + difficulty * 20.0
	entity.hp = entity.max_hp
	entity.speed = 45.0 + difficulty * 7.0
	if entity.get("_damage_bar_ratio") != null:
		entity._damage_bar_ratio = 1.0

	if entity.has_method("_generate_points"):
		entity._generate_points()
	elif entity.has_method("_generate_tendrils"):
		entity._generate_tendrils()

	$EntityLayer.add_child(entity)

func _update_coffin_visual() -> void:
	var ratio: float = coffin_hp / coffin_max_hp

	if ratio > 0.7:
		_coffin_rect.color = Color(1.0, 1.0, 1.0, 1.0)
	elif ratio > 0.4:
		_coffin_rect.color = Color(1.0, 0.7, 0.7, 1.0)
	elif ratio > 0.1:
		# 위급 - 빨강 + 점멸
		var pulse: float = (sin(_elapsed_time * 12.0) + 1.0) * 0.5
		var bright: float = lerp(0.4, 1.0, pulse)
		_coffin_rect.color = Color(1.0, 0.3 * bright, 0.3 * bright, 1.0)
	else:
		# 사망 직전 - 강한 빨강 + 빠른 점멸
		var pulse2: float = (sin(_elapsed_time * 20.0) + 1.0) * 0.5
		var bright2: float = lerp(0.3, 1.0, pulse2)
		_coffin_rect.color = Color(1.0, 0.1 * bright2, 0.1 * bright2, 1.0)

func _check_coffin_collision() -> void:
	var coffin_rect: Rect2 = Rect2(_coffin_rect.position, _coffin_rect.size)
	for entity in get_tree().get_nodes_in_group("blood_entities"):
		var r: float = entity.radius if "radius" in entity else 30.0
		var expanded: Rect2 = Rect2(
			coffin_rect.position - Vector2(r, r),
			coffin_rect.size + Vector2(r * 2, r * 2)
		)
		if expanded.has_point(entity.global_position):
			var hit_pos: Vector2 = entity.global_position
			entity.remove_from_group("blood_entities")
			entity.queue_free()
			coffin_hp -= 10.0
			coffin_hp = max(coffin_hp, 0.0)
			reset_combo()
			trigger_hitstop(0.1)  # 관 타격 시 더 강한 히트스탑
			var cm = _get_chat_manager()
			if cm:
				cm.send_chat("hit")
			_viewers += randi_range(1, 8)
			_likes += randi_range(0, 3)
			_update_viewer_ui()
			_trigger_shake()
			_trigger_vignette()
			_trigger_shockwave(hit_pos)
			_trigger_coffin_push(hit_pos)
			_show_hp_bar()
			if coffin_hp <= 0.0:
				_game_over()

func _show_hp_bar(from_damage: bool = true) -> void:
	var hp_fill = $CanvasLayer/CoffinHPBar/HPFill
	var damage_bar = $CanvasLayer/CoffinHPBar/DamageBar
	var label = $CanvasLayer/CoffinHPBar/HPBarLabel

	var ratio: float = coffin_hp / coffin_max_hp

	hp_fill.offset_right = 1200.0 * ratio
	label.text = "HP %d / %d" % [int(coffin_hp), int(coffin_max_hp)]

	if from_damage:
		damage_bar.modulate = Color(1, 1, 1, 1)
		var damage_ratio: float = (coffin_hp + 10.0) / coffin_max_hp
		damage_bar.offset_right = 1200.0 * damage_ratio
		if _damage_tween:
			_damage_tween.kill()
		_damage_tween = create_tween()
		_damage_tween.tween_interval(0.25)
		_damage_tween.tween_property(
			damage_bar, "offset_right", 1200.0 * ratio, 0.85
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	else:
		if _damage_tween:
			_damage_tween.kill()
		damage_bar.offset_right = 1200.0 * ratio
		damage_bar.modulate = Color(1, 1, 1, 0)

	_fade_hp_bar(true)
	_hp_visible = true
	_hp_hide_timer = 2.8

func _apply_shake(delta: float) -> void:
	if _shake_duration > 0:
		_shake_duration -= delta
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		$EntityLayer.position = _shake_offset
	else:
		_shake_offset = Vector2.ZERO
		$EntityLayer.position = Vector2.ZERO

func heal_coffin(amount: float) -> void:
	if coffin_hp >= coffin_max_hp:
		return
	var actual: float = min(amount, coffin_max_hp - coffin_hp)
	var old_ratio: float = coffin_hp / coffin_max_hp
	coffin_hp += actual
	coffin_hp = min(coffin_hp, coffin_max_hp)
	var new_ratio: float = coffin_hp / coffin_max_hp

	_show_hp_bar(false)

	var heal_bar: ColorRect = $CanvasLayer/CoffinHPBar/HealBar
	heal_bar.offset_left = 1200.0 * old_ratio
	heal_bar.offset_right = 1200.0 * old_ratio
	heal_bar.modulate = Color(1, 1, 1, 1)

	var heal_tween: Tween = create_tween()
	heal_tween.tween_property(
		heal_bar, "offset_right", 1200.0 * new_ratio, 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	heal_tween.tween_property(heal_bar, "modulate", Color(1, 1, 1, 0), 0.25).set_ease(Tween.EASE_IN)
	heal_tween.tween_callback(func():
		heal_bar.offset_left = 0.0
		heal_bar.offset_right = 0.0
	)

	var tw = create_tween()
	tw.tween_property(_coffin_rect, "modulate", Color(1.0, 0.5, 0.5, 1.0), 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(_coffin_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2).set_ease(Tween.EASE_IN)

func _activate_coffin_barrier() -> void:
	_coffin_barrier_active = true

func _deactivate_coffin_barrier() -> void:
	_coffin_barrier_active = false

func _check_coffin_barrier() -> void:
	var coffin_center = _coffin_rect.global_position + _coffin_rect.size / 2.0
	var entities = get_tree().get_nodes_in_group("blood_entities")
	for entity in entities:
		var dist = entity.global_position.distance_to(coffin_center)
		if dist <= 260.0 and dist >= 240.0:
			if entity.has_method("apply_slow"):
				entity.apply_slow(0.5, 1.0)

func _trigger_coffin_push(hit_pos: Vector2) -> void:
	var coffin_center: Vector2 = _coffin_rect.global_position + _coffin_rect.size / 2
	var push_dir: Vector2 = (coffin_center - hit_pos).normalized()
	if push_dir.is_zero_approx():
		push_dir = Vector2.RIGHT
	var push_amount: float = 14.0
	var pushed_pos: Vector2 = _coffin_base_pos + push_dir * push_amount

	if _coffin_push_tween:
		_coffin_push_tween.kill()
	_coffin_push_tween = create_tween()
	_coffin_push_tween.tween_property(_coffin_rect, "position", pushed_pos, 0.04).set_ease(Tween.EASE_OUT)
	_coffin_push_tween.tween_property(_coffin_rect, "position", _coffin_base_pos, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

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
	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

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
	Engine.time_scale = 1.0
	_is_game_over = true
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("gameover")
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

	var coffin_center: Vector2 = _coffin_rect.position + _coffin_rect.size / 2

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

func _escape_success() -> void:
	Engine.time_scale = 1.0
	_is_game_over = true
	var cm = _get_chat_manager()
	if cm:
		cm.send_chat("clear")
	_viewers += randi_range(100, 300)
	_likes += randi_range(50, 150)
	_update_viewer_ui()
	ResourceManager.add_ruby(3)
	_show_ruby_popup("클리어 보상! 🔴+3")
	get_tree().paused = true

	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$CanvasLayer.add_child(overlay)

	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color", Color(0.0, 0.0, 0.05, 0.85), 1.2)
	await tween.finished

	var label1: Label = Label.new()
	label1.text = "탈출 성공"
	label1.add_theme_font_size_override("font_size", 28)
	label1.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1.0))
	label1.set_anchors_preset(Control.PRESET_CENTER)
	label1.offset_top = -80
	label1.offset_left = -100
	$CanvasLayer.add_child(label1)

	await get_tree().create_timer(0.8).timeout

	var label2: Label = Label.new()
	label2.text = "획득 재화: 🩸 %d" % ResourceManager.blood
	label2.add_theme_font_size_override("font_size", 24)
	label2.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 1.0))
	label2.set_anchors_preset(Control.PRESET_CENTER)
	label2.offset_top = -30
	label2.offset_left = -120
	$CanvasLayer.add_child(label2)

	await get_tree().create_timer(0.8).timeout

	var label3: Label = Label.new()
	label3.text = "생존 시간: %d초" % int(_elapsed_time)
	label3.add_theme_font_size_override("font_size", 20)
	label3.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	label3.set_anchors_preset(Control.PRESET_CENTER)
	label3.offset_top = 10
	label3.offset_left = -100
	$CanvasLayer.add_child(label3)

	await get_tree().create_timer(1.0).timeout

	var label4: Label = Label.new()
	label4.text = "[ R ] 다시 도전"
	label4.add_theme_font_size_override("font_size", 18)
	label4.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	label4.set_anchors_preset(Control.PRESET_CENTER)
	label4.offset_top = 60
	label4.offset_left = -80
	$CanvasLayer.add_child(label4)

func _input(event: InputEvent) -> void:
	# 좌클릭: 노드 정보 패널 밖 클릭 시 닫기 / SHIFT+관 클릭 시 관-노드 연결
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _node_info_panel and is_instance_valid(_node_info_panel):
			var panel_rect = _node_info_panel.get_global_rect()
			var mouse_pos = get_viewport().get_mouse_position()
			if not panel_rect.has_point(mouse_pos):
				_close_node_info_panel()

		# SHIFT + 관 클릭 시 관-노드 시너지 연결
		if Input.is_key_pressed(KEY_SHIFT):
			var coffin = $CanvasLayer/Coffin
			var coffin_rect = Rect2(coffin.global_position, coffin.size)
			if coffin_rect.has_point(get_viewport().get_mouse_position()):
				var cm = get_tree().get_first_node_in_group("connection_manager")
				var pending = cm.get_pending() if cm else null
				if cm and pending and cm.has_method("try_connect_to_coffin"):
					cm.try_connect_to_coffin(pending)
					get_viewport().set_input_as_handled()

	# 우클릭: 시너지 연결 대기 중이면 취소, 아니면 노드 제거 (_input에서 처리해 GUI보다 먼저)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var cm = get_tree().get_first_node_in_group("connection_manager")
		if cm and cm._pending != null:
			# 시너지 연결 취소
			cm._pending.is_pending_connection = false
			cm._pending._is_first_selected = false
			cm._clear_highlights()
			cm._pending = null
			cm.queue_redraw()
			get_viewport().set_input_as_handled()
			return
		# 연결 대기 중 아닐 때 노드 제거
		var clicked_node = _get_hovered_game_node()
		if clicked_node:
			clicked_node.on_right_click()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if left_open:
				_slide_left_close()
			else:
				_slide_left_open()
			left_open = !left_open

		if event.keycode == KEY_E:
			if _right_open:
				_slide_right_close()
			else:
				_slide_right_open()
			_right_open = !_right_open

		if event.keycode == KEY_R and _is_game_over:
			ResourceManager.total_runs += 1
			ResourceManager.total_kills += _kill_count
			Engine.time_scale = 1.0
			get_tree().paused = false
			get_tree().reload_current_scene()

		if event.keycode == KEY_X and event.pressed:
			_recall_slots_to_panel()

		if event.keycode == KEY_SPACE:
			if _selected_nodes.size() == 1:
				var node = _selected_nodes[0]
				if is_instance_valid(node) and node.is_placed:
					_open_upgrade_menu(node)

func _open_upgrade_menu(node: Node2D) -> void:
	# 기존 메뉴 있으면 제거
	var existing = get_tree().get_first_node_in_group("upgrade_menu")
	if existing:
		existing.queue_free()
		return

	if node.upgrade_level >= node.max_upgrade:
		_show_deny_popup("최대 강화 완료")
		return

	# 강화 비용 계산
	var costs: Array = [20, 35, 55]
	var cost: int = costs[node.upgrade_level]

	# 팝업 생성
	var popup: Panel = Panel.new()
	popup.add_to_group("upgrade_menu")
	popup.custom_minimum_size = Vector2(180, 120)
	popup.global_position = node.global_position - Vector2(90, 140)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.0, 0.0, 0.95)
	style.border_color = node.node_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	popup.add_theme_stylebox_override("panel", style)

	# 강화 버튼
	var btn: Button = Button.new()
	btn.text = "강화 LV.%d → LV.%d\n🩸%d" % [
		node.upgrade_level + 1, node.upgrade_level + 2, cost]
	btn.custom_minimum_size = Vector2(160, 60)
	btn.position = Vector2(10, 10)
	var node_ref = node
	btn.pressed.connect(func():
		if ResourceManager.blood < cost:
			_show_deny_popup("혈액 부족")
			return
		ResourceManager.spend_blood(cost)
		node_ref.upgrade_level += 1
		_apply_upgrade(node_ref)
		_play_upgrade_effect(node_ref)
		popup.queue_free()
	)
	popup.add_child(btn)

	# 닫기
	var close: Button = Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(24, 24)
	close.position = Vector2(150, 4)
	close.pressed.connect(func(): popup.queue_free())
	popup.add_child(close)

	$CanvasLayer.add_child(popup)

func _apply_upgrade(node: Node2D) -> void:
	match node.node_id:
		"absorb":
			node.base_damage = int(node.base_damage * 1.5)
		"freeze":
			node.slow_amount = min(node.slow_amount + 0.15, 0.95)
			node.slow_duration += 1.0
		"resonate":
			node.cooldown_reduction = min(node.cooldown_reduction + 0.15, 0.8)

func _play_upgrade_effect(node: Node2D) -> void:
	if not is_instance_valid(node) or not node.get("node_color"):
		return
	var color: Color = node.node_color
	var center: Vector2 = node.global_position
	var count: int = 25
	var orbit_radius: float = 200.0

	# === 페이즈 1: Line2D 파장 링 (퍼지며 얇아지고 사라짐) ===
	var wave_points: int = 64
	var ring: Line2D = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(color.r, color.g, color.b, 0.9)
	ring.antialiased = true
	for p in range(wave_points + 1):
		var a: float = (TAU / wave_points) * p
		ring.add_point(center + Vector2(cos(a), sin(a)) * 20.0)
	$EntityLayer.add_child(ring)

	var ring_cb: Callable = func(t: float) -> void:
		if not is_instance_valid(ring):
			return
		var radius: float = lerp(20.0, 220.0, t)
		var alpha: float = lerp(0.9, 0.0, t)
		ring.width = lerp(4.0, 0.5, t)
		ring.default_color = Color(color.r, color.g, color.b, alpha)
		for p in range(wave_points + 1):
			var a: float = (TAU / wave_points) * p
			ring.set_point_position(p, center + Vector2(cos(a), sin(a)) * radius)

	var ring_tween: Tween = create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_method(ring_cb, 0.0, 1.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	ring_tween.tween_callback(ring.queue_free).set_delay(0.4)

	# 2번째 잔파
	var ring2: Line2D = Line2D.new()
	ring2.width = 1.5
	ring2.default_color = Color(color.r, color.g, color.b, 0.5)
	ring2.antialiased = true
	for p in range(wave_points + 1):
		var a: float = (TAU / wave_points) * p
		ring2.add_point(center + Vector2(cos(a), sin(a)) * 20.0)
	$EntityLayer.add_child(ring2)

	var ring2_cb: Callable = func(t: float) -> void:
		if not is_instance_valid(ring2):
			return
		var radius: float = lerp(20.0, 280.0, t)
		var alpha: float = lerp(0.5, 0.0, t)
		ring2.width = lerp(2.0, 0.3, t)
		ring2.default_color = Color(color.r, color.g, color.b, alpha)
		for p in range(wave_points + 1):
			var a: float = (TAU / wave_points) * p
			ring2.set_point_position(p, center + Vector2(cos(a), sin(a)) * radius)

	var ring2_tween: Tween = create_tween()
	ring2_tween.tween_interval(0.1)
	ring2_tween.tween_method(ring2_cb, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	ring2_tween.tween_callback(ring2.queue_free).set_delay(0.6)

	# === 페이즈 2: 파티클 생성 (빠른 회전 + 반경 확장 + 감속 → orbit 도달) ===
	var orbit_angles: Array = []
	orbit_angles.resize(count)
	var dots: Array = []
	var tails: Array = []
	var expand_done_counter: RefCounted = RefCounted.new()
	expand_done_counter.set_meta("done", 0)

	for i in range(count):
		var final_angle: float = (TAU / count) * i + randf_range(-0.3, 0.3)
		var final_radius: float = randf_range(orbit_radius * 0.6, orbit_radius)
		orbit_angles[i] = final_angle

		var dot_size: float = randf_range(7, 16)
		var glow_size: float = dot_size * 3.5
		var core_size: float = dot_size * 0.4
		# 1. 외곽 글로우 (가장 크고 흐림)
		var glow: Panel = Panel.new()
		glow.size = Vector2(glow_size, glow_size)
		var gs: StyleBoxFlat = StyleBoxFlat.new()
		gs.set_corner_radius_all(int(glow_size / 2))
		gs.bg_color = Color(color.r, color.g, color.b, 0.15)
		glow.add_theme_stylebox_override("panel", gs)
		glow.position = center - Vector2(glow_size, glow_size) * 0.5
		glow.z_index = 10
		$EntityLayer.add_child(glow)
		# 2. 중간 색상 원 (노드 색)
		var dot: Panel = Panel.new()
		dot.size = Vector2(dot_size, dot_size)
		var s: StyleBoxFlat = StyleBoxFlat.new()
		s.set_corner_radius_all(int(dot_size / 2))
		s.bg_color = color
		dot.add_theme_stylebox_override("panel", s)
		dot.position = center - Vector2(dot_size, dot_size) * 0.5
		dot.z_index = 11
		$EntityLayer.add_child(dot)
		# 3. 중심 흰색 점 (가장 작고 밝음)
		var core: Panel = Panel.new()
		core.size = Vector2(core_size, core_size)
		var cs: StyleBoxFlat = StyleBoxFlat.new()
		cs.set_corner_radius_all(int(core_size / 2))
		cs.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		core.add_theme_stylebox_override("panel", cs)
		core.position = center - Vector2(core_size, core_size) * 0.5
		core.z_index = 12
		$EntityLayer.add_child(core)

		var tail: Line2D = Line2D.new()
		tail.default_color = color
		tail.antialiased = true
		# 파티클쪽 두껍게(거의 크기 동일), 꼬리끝 가늘게
		var wcurve: Curve = Curve.new()
		wcurve.add_point(Vector2(0.0, 0.15))  # 꼬리끝: 가늘게
		wcurve.add_point(Vector2(1.0, 1.0))  # 파티클쪽: 최대 두께
		tail.width_curve = wcurve
		tail.width = dot_size * 0.9  # 파티클 크기에 맞춘 최대 굵기
		for _p in range(8):
			tail.add_point(center)
		$EntityLayer.add_child(tail)
		tail.visible = false

		dots.append({"node": dot, "glow": glow, "core": core, "size": dot_size, "glow_size": glow_size, "core_size": core_size, "radius": final_radius})
		tails.append(tail)

		# 빠른 회전 + 반경 확장 트윈
		var start_angle: float = final_angle - TAU * randf_range(1.5, 2.5)
		var captured_dot: Panel = dot
		var captured_tail: Line2D = tail
		var captured_glow: Panel = glow
		var captured_core: Panel = core
		var captured_size: float = dot_size
		var captured_glow_size: float = glow_size
		var captured_core_size: float = core_size
		var captured_start_angle: float = start_angle
		var captured_final_angle: float = final_angle
		var captured_final_radius: float = final_radius
		var pos_history: Array[Vector2] = []
		for _h in range(8):
			pos_history.append(center)

		var expand_duration: float = randf_range(1.5, 2.2)
		var captured_i: int = i
		orbit_angles[captured_i] = captured_start_angle

		var expand_cb: Callable = func(t: float) -> void:
			if not is_instance_valid(captured_dot):
				return
			var eased_t: float = 1.0 - pow(1.0 - t, 3.0)
			var spin_speed: float = lerp(8.0, 0.3, eased_t)
			orbit_angles[captured_i] += spin_speed * _last_delta
			var cur_angle: float = orbit_angles[captured_i]
			var cur_radius: float = lerp(0.0, captured_final_radius, eased_t)
			var cur_pos: Vector2 = center + Vector2(cos(cur_angle), sin(cur_angle)) * cur_radius
			var half_dot: Vector2 = Vector2(captured_size, captured_size) * 0.5
			var half_glow: Vector2 = Vector2(captured_glow_size, captured_glow_size) * 0.5
			var half_core: Vector2 = Vector2(captured_core_size, captured_core_size) * 0.5
			captured_dot.position = cur_pos - half_dot
			if is_instance_valid(captured_glow):
				captured_glow.position = cur_pos - half_glow
			if is_instance_valid(captured_core):
				captured_core.position = cur_pos - half_core
			pos_history.pop_front()
			pos_history.append(cur_pos)
			if is_instance_valid(captured_tail):
				captured_tail.visible = true
				for p in range(8):
					captured_tail.set_point_position(p, pos_history[p])
				captured_tail.width = captured_size * 0.9

		var expand_tw: Tween = create_tween()
		expand_tw.tween_method(expand_cb, 0.0, 1.0, expand_duration).set_trans(Tween.TRANS_LINEAR)
		expand_tw.tween_callback(func() -> void:
			orbit_angles[captured_i] = captured_final_angle
			var n: int = expand_done_counter.get_meta("done") + 1
			expand_done_counter.set_meta("done", n)
		)

	# expand 전부 완료까지 대기 후 흡수 페이즈
	while expand_done_counter.get_meta("done") < count:
		await get_tree().process_frame

	# === 페이즈 3: 흡수 + 노드 스케일 바운스 ===
	var counter: RefCounted = RefCounted.new()
	counter.set_meta("arrived", 0)
	counter.set_meta("restore_done", false)

	# 흡수 중 노드 중앙 발광 (부드러운 산란 - 8층 미세 그라데이션)
	var ng_size: float = 44.0
	var glow_container: Node2D = Node2D.new()
	glow_container.position = node.global_position
	var layer_scales: Array[float] = [1.0, 1.12, 1.25, 1.4, 1.58, 1.78, 2.0, 2.25]
	var layer_alphas: Array[float] = [0.42, 0.34, 0.27, 0.2, 0.14, 0.09, 0.05, 0.02]
	for l in range(8):
		var ls: float = ng_size * layer_scales[l]
		var lp: Panel = Panel.new()
		lp.size = Vector2(ls, ls)
		lp.position = Vector2(-ls, -ls) * 0.5
		lp.pivot_offset = Vector2(ls, ls) * 0.5
		var lps: StyleBoxFlat = StyleBoxFlat.new()
		lps.set_corner_radius_all(int(ls / 2))
		lps.bg_color = Color(color.r, color.g, color.b, 0.0)
		lp.add_theme_stylebox_override("panel", lps)
		lp.set_meta("base_alpha", layer_alphas[l])
		glow_container.add_child(lp)
	$EntityLayer.add_child(glow_container)

	if _upgrade_scale_tween:
		_upgrade_scale_tween.kill()
	var scale_tween: Tween = create_tween()
	scale_tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in range(count):
		var dot_center_pos: Vector2 = dots[i]["node"].position + Vector2(dots[i]["size"], dots[i]["size"]) * 0.5
		var captured_start: Vector2 = dot_center_pos
		var captured_dot: Panel = dots[i]["node"]
		var captured_tail: Line2D = tails[i]
		var captured_glow: Panel = dots[i]["glow"]
		var captured_core: Panel = dots[i]["core"]
		var captured_size: float = dots[i]["size"]
		var captured_glow_size: float = dots[i]["glow_size"]
		var captured_core_size: float = dots[i]["core_size"]
		var pos_history: Array = []
		for _h in range(8):
			pos_history.append(captured_start)

		var delay: float = randf_range(0.0, 0.2)
		var absorb_tw: Tween = create_tween()
		absorb_tw.tween_interval(delay)
		absorb_tw.tween_method(
			func(t: float) -> void: _absorb_particle(captured_dot, captured_tail, captured_start, center, captured_size, pos_history, t, captured_glow, captured_core, captured_glow_size, captured_core_size),
			0.0, 1.0, randf_range(0.4, 0.7)
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

		absorb_tw.tween_callback(func() -> void:
			if is_instance_valid(captured_dot):
				captured_dot.queue_free()
			if is_instance_valid(captured_tail):
				captured_tail.queue_free()
			if is_instance_valid(captured_glow):
				captured_glow.queue_free()
			if is_instance_valid(captured_core):
				captured_core.queue_free()
			var n: int = counter.get_meta("arrived") + 1
			counter.set_meta("arrived", n)
			# arrived 증가할수록 발광 세기 증가 (다층 산란)
			var glow_intensity: float = float(n) / float(count)
			for ch in glow_container.get_children():
				if ch is Panel:
					var base_a: float = ch.get_meta("base_alpha", 0.5)
					var lp_style: StyleBoxFlat = StyleBoxFlat.new()
					lp_style.set_corner_radius_all(int(ch.size.x / 2))
					lp_style.bg_color = Color(color.r, color.g, color.b, glow_intensity * base_a)
					ch.add_theme_stylebox_override("panel", lp_style)
			glow_container.scale = Vector2(1.0 + glow_intensity * 0.9, 1.0 + glow_intensity * 0.9)
			if n >= count and not counter.get_meta("restore_done") and is_instance_valid(node):
				counter.set_meta("restore_done", true)
				call_deferred("_restore_node_scale_and_wave", node, color, glow_container)
		)

func _restore_node_scale_and_wave(node: Node2D, color: Color, glow_container: Node2D = null) -> void:
	if not is_instance_valid(node):
		return
	if _upgrade_scale_tween:
		_upgrade_scale_tween.kill()
	_upgrade_scale_tween = create_tween()
	_upgrade_scale_tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_upgrade_scale_tween.tween_callback(func() -> void:
		_upgrade_scale_tween = null
	)

	# 발광 최대 → 서서히 꺼짐 + 잔광(afterglow) 효과
	if is_instance_valid(glow_container):
		var fade_glow: Tween = create_tween()
		fade_glow.set_parallel(true)
		fade_glow.tween_property(glow_container, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN)
		fade_glow.tween_property(glow_container, "scale", Vector2(2.0, 2.0), 0.5).set_ease(Tween.EASE_OUT)
		fade_glow.tween_callback(glow_container.queue_free).set_delay(0.5)

		# 잔광: 주 발광이 꺼질 때 남는 부드러운 잔상
		var center_pos: Vector2 = node.global_position
		var ag_size: float = 64.0
		var afterglow: Panel = Panel.new()
		afterglow.size = Vector2(ag_size, ag_size)
		afterglow.position = center_pos - Vector2(ag_size, ag_size) * 0.5
		afterglow.pivot_offset = Vector2(ag_size, ag_size) * 0.5
		var ags: StyleBoxFlat = StyleBoxFlat.new()
		ags.set_corner_radius_all(int(ag_size / 2))
		ags.bg_color = Color(color.r, color.g, color.b, 0.12)
		afterglow.add_theme_stylebox_override("panel", ags)
		$EntityLayer.add_child(afterglow)
		var ag_tween: Tween = create_tween()
		ag_tween.set_parallel(true)
		ag_tween.tween_property(afterglow, "modulate", Color(1, 1, 1, 0), 1.0).set_ease(Tween.EASE_IN)
		ag_tween.tween_property(afterglow, "scale", Vector2(1.8, 1.8), 1.0).set_ease(Tween.EASE_OUT)
		ag_tween.tween_callback(afterglow.queue_free).set_delay(1.0)

	# node 자체 순간 발광 후 원상복구
	node.modulate = Color(1.0 + color.r * 2.0, 1.0 + color.g * 2.0, 1.0 + color.b * 2.0, 1.0)
	var node_fade: Tween = create_tween()
	node_fade.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.6).set_ease(Tween.EASE_IN)

	_final_wave(node, color)

func _absorb_particle(dot: Panel, tail: Line2D, start: Vector2, center: Vector2, size: float, pos_history: Array, t: float, glow: Panel = null, core: Panel = null, glow_size: float = 0.0, core_size: float = 0.0) -> void:
	if not is_instance_valid(dot):
		return
	var cur_pos: Vector2 = start.lerp(center, t)
	var half_dot: Vector2 = Vector2(size, size) * 0.5
	dot.position = cur_pos - half_dot
	if is_instance_valid(glow) and glow_size > 0.0:
		glow.position = cur_pos - Vector2(glow_size, glow_size) * 0.5
	if is_instance_valid(core) and core_size > 0.0:
		core.position = cur_pos - Vector2(core_size, core_size) * 0.5
	pos_history.pop_front()
	pos_history.append(cur_pos)
	if is_instance_valid(tail):
		for p in range(8):
			tail.set_point_position(p, pos_history[p])
		# 흡수 시 전체 축소 (gradient 유지: 파티클쪽 두껍게, 꼬리끝 가늘게)
		tail.width = lerp(size * 0.9, 0.2, t)

func _final_wave(node: Node2D, color: Color) -> void:
	if not is_instance_valid(node):
		return
	var center: Vector2 = node.global_position

	for r in range(2):
		var wave: Panel = Panel.new()
		var wsize: float = 80.0
		wave.size = Vector2(wsize, wsize)
		wave.position = center - Vector2(wsize, wsize) * 0.5
		wave.pivot_offset = Vector2(wsize, wsize) * 0.5
		var ws: StyleBoxFlat = StyleBoxFlat.new()
		ws.set_corner_radius_all(int(wsize / 2))
		ws.bg_color = Color(color.r, color.g, color.b, 0.0)
		ws.border_color = Color(color.r, color.g, color.b, 0.6 - r * 0.2)
		ws.set_border_width_all(2)
		wave.add_theme_stylebox_override("panel", ws)
		$EntityLayer.add_child(wave)

		var wt: Tween = create_tween()
		wt.set_parallel(true)
		wt.tween_property(wave, "scale", Vector2(3.5, 3.5), 0.6).set_ease(Tween.EASE_OUT).set_delay(r * 0.1)
		wt.tween_property(wave, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN).set_delay(r * 0.1 + 0.1)
		wt.tween_callback(wave.queue_free).set_delay(r * 0.1 + 0.6)

func _update_blackhole_streak(
	dot: Panel, streak: Line2D, dot_size: float,
	start_pos: Vector2, center: Vector2, t: float
) -> void:
	if not is_instance_valid(dot):
		return
	# 단순 lerp - 좌표 변환 없이 글로벌 그대로
	var pos: Vector2 = start_pos.lerp(center, t)
	dot.position = pos - Vector2(dot_size, dot_size) * 0.5
	streak.set_point_position(0, pos)
	streak.set_point_position(1, start_pos)

func _update_burst_shard_position(shard: Panel, shard_tail: Line2D, local_center: Vector2, local_end: Vector2, t: float) -> void:
	var pos: Vector2 = local_center.lerp(local_end, t)
	shard.position = pos - shard.size * 0.5
	shard_tail.set_point_position(0, local_center)
	shard_tail.set_point_position(1, pos)

func _update_spark_position(spark: Panel, local_center: Vector2, local_end: Vector2, t: float) -> void:
	spark.position = local_center.lerp(local_end, t) - Vector2(2, 2)

func _burst_upgrade(node: Node2D, color: Color) -> void:
	if not is_instance_valid(node):
		return
	if _upgrade_scale_tween:
		_upgrade_scale_tween.kill()
	var center: Vector2 = node.global_position
	var current_scale: float = node.scale.x

	# 순간 플래시 (팡 순간 빛남)
	node.modulate = Color(1.4, 1.4, 1.4, 1.0)

	var burst: Tween = create_tween()
	burst.set_parallel(true)
	burst.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(0.06).set_ease(Tween.EASE_OUT)
	burst.tween_property(node, "scale", Vector2(current_scale * 1.25, current_scale * 1.25), 0.06).set_ease(Tween.EASE_OUT)

	# 2겹 링 (안쪽 빠르게, 바깥 느리게)
	for r in range(2):
		var ring: Panel = Panel.new()
		var ring_size: int = 50 + r * 40
		ring.size = Vector2(ring_size, ring_size)
		ring.position = center - Vector2(ring_size, ring_size) * 0.5
		ring.pivot_offset = Vector2(ring_size, ring_size) * 0.5
		ring.z_index = 48 + r
		var rs: StyleBoxFlat = StyleBoxFlat.new()
		rs.set_corner_radius_all(ring_size / 2)
		rs.bg_color = Color(color.r, color.g, color.b, 0.12 - r * 0.04)
		rs.border_color = Color(color.r, color.g, color.b, 0.95 - r * 0.2)
		rs.set_border_width_all(4 - r)
		ring.add_theme_stylebox_override("panel", rs)
		$EntityLayer.add_child(ring)
		var scale_tgt: float = 2.8 + r * 0.8
		var ring_dur: float = 0.25 + r * 0.12
		var ring_delay: float = r * 0.04
		var ring_ref: Panel = ring
		burst.tween_property(ring, "scale", Vector2(scale_tgt, scale_tgt), ring_dur).set_delay(ring_delay).set_ease(Tween.EASE_OUT)
		burst.tween_property(ring, "modulate", Color(1, 1, 1, 0), ring_dur * 0.85).set_delay(ring_delay + 0.03).set_ease(Tween.EASE_IN)
		get_tree().create_timer(ring_delay + ring_dur).timeout.connect(func() -> void:
			if is_instance_valid(ring_ref):
				ring_ref.queue_free()
		)

	# 스파크 12개 (작고 빠른 점)
	for i in range(12):
		var angle: float = (TAU / 12) * i + randf_range(-0.12, 0.12)
		var dist: float = randf_range(50, 90)
		var local_end: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		var spark: Panel = Panel.new()
		spark.size = Vector2(4, 4)
		spark.position = center - Vector2(2, 2)
		spark.z_index = 46
		var sp_s: StyleBoxFlat = StyleBoxFlat.new()
		sp_s.set_corner_radius_all(2)
		sp_s.bg_color = Color(color.r, color.g, color.b, 1.0)
		spark.add_theme_stylebox_override("panel", sp_s)
		$EntityLayer.add_child(spark)
		var sp_dur: float = randf_range(0.12, 0.2)
		var spark_ref: Panel = spark
		burst.tween_method(
			_update_spark_position.bind(spark, center, local_end),
			0.0, 1.0, sp_dur
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		burst.tween_property(spark, "modulate", Color(color.r, color.g, color.b, 0), sp_dur).set_ease(Tween.EASE_IN)
		get_tree().create_timer(sp_dur).timeout.connect(func() -> void:
			if is_instance_valid(spark_ref):
				spark_ref.queue_free()
		)

	# 방사형 입자 20개 (혜성 꼬리)
	for i in range(20):
		var angle: float = (TAU / 20) * i + randf_range(-0.1, 0.1)
		var dist: float = randf_range(100, 180)
		var local_end: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist

		var shard: Panel = Panel.new()
		shard.size = Vector2(randf_range(8, 18), randf_range(8, 18))
		shard.position = center - shard.size * 0.5
		shard.z_index = 45
		var ss: StyleBoxFlat = StyleBoxFlat.new()
		ss.set_corner_radius_all(int(min(shard.size.x, shard.size.y) / 2))
		ss.bg_color = Color(color.r, color.g, color.b, 0.95)
		ss.border_color = Color(color.r, color.g, color.b, 0.5)
		ss.set_border_width_all(1)
		shard.add_theme_stylebox_override("panel", ss)
		$EntityLayer.add_child(shard)

		var shard_tail: Line2D = Line2D.new()
		shard_tail.default_color = Color(color.r, color.g, color.b, 0.7)
		shard_tail.width = randf_range(1.5, 2.5)
		shard_tail.add_point(center)
		shard_tail.add_point(center)
		shard_tail.z_index = 44
		$EntityLayer.add_child(shard_tail)

		var dur: float = randf_range(0.28, 0.45)
		var shard_ref: Panel = shard
		var tail_ref: Line2D = shard_tail
		burst.tween_method(
			_update_burst_shard_position.bind(shard, shard_tail, center, local_end),
			0.0, 1.0, dur
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		burst.tween_property(shard, "modulate", Color(color.r, color.g, color.b, 0), dur * 0.75).set_ease(Tween.EASE_IN)
		burst.tween_property(shard_tail, "modulate", Color(1, 1, 1, 0), dur * 0.75).set_ease(Tween.EASE_IN)

		get_tree().create_timer(dur).timeout.connect(func() -> void:
			if is_instance_valid(shard_ref):
				shard_ref.queue_free()
			if is_instance_valid(tail_ref):
				tail_ref.queue_free()
		)

	# 팡! 후 서서히 원상복구
	burst.chain().tween_property(node, "scale", Vector2(1.0, 1.0), 0.65).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _recall_slots_to_panel() -> void:
	if _slots_in_panel:
		_show_deny_popup("이미 회수했습니다 [X]")
		return

	var recalled_count = 0
	for i in range(_slot_data.size()):
		if _slot_data[i] != "":
			recalled_count += 1
			var idx = i
			var delay = idx * 0.08
			get_tree().create_timer(delay).timeout.connect(func(): _fire_slot_wave(idx))
		_slot_data[i] = ""
		_update_slot_visual(i)

	if recalled_count > 0:
		_build_owned_nodes()
		_slots_in_panel = true
		if not left_open:
			_slide_left_open()
			left_open = true
		_show_deny_popup("노드 %d개 회수됨" % recalled_count)
	else:
		_show_deny_popup("회수할 노드 없음")

	_hint_hiding = false
	_hint_area.visible = false  # 완전히 숨긴 상태로 리셋
	_indicator_was_hidden = true  # 다시 올라올 수 있게
	_slots_in_panel = false  # 인디케이터 다시 올라올 수 있게 리셋
	_update_slot_count_label()

func _fire_slot_wave(index: int) -> void:
	var slots = _dots_container.get_children()
	if index >= slots.size():
		return
	var slot = slots[index]

	var effect = Node2D.new()
	$EntityLayer.add_child(effect)
	effect.position = Vector2(slot.global_position.x + 32, 980)

	# 중앙 플래시: 순간 번쩍
	var flash = Panel.new()
	flash.size = Vector2(48, 48)
	flash.position = Vector2(-24, -24)
	flash.pivot_offset = Vector2(24, 24)
	var flash_style = StyleBoxFlat.new()
	flash_style.set_corner_radius_all(24)
	flash_style.bg_color = Color(1.0, 0.9, 0.5, 0.8)
	flash_style.set_border_width_all(0)
	flash.add_theme_stylebox_override("panel", flash_style)
	effect.add_child(flash)
	var flash_tw = create_tween()
	flash_tw.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.08).set_ease(Tween.EASE_OUT)
	flash_tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)

	# 3겹 리플: 순차 확장 + 페이드
	for j in range(3):
		var ring = Panel.new()
		ring.size = Vector2(64, 64)
		ring.position = Vector2(-32, -32)
		ring.pivot_offset = Vector2(32, 32)
		ring.modulate.a = 0.0
		var ring_style = StyleBoxFlat.new()
		ring_style.set_corner_radius_all(32)
		var alpha_inner = 0.25 - j * 0.06
		var alpha_border = 0.7 - j * 0.15
		ring_style.bg_color = Color(1.0, 0.4, 0.2, alpha_inner)
		ring_style.border_color = Color(1.0, 0.5, 0.3, alpha_border)
		ring_style.set_border_width_all(6)
		ring.add_theme_stylebox_override("panel", ring_style)
		effect.add_child(ring)

		var tw = create_tween()
		tw.tween_interval(j * 0.06)
		tw.tween_property(ring, "modulate:a", 1.0, 0.02)
		tw.tween_property(ring, "scale", Vector2(2.8, 2.8), 0.4)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)\
			.set_delay(0.08).set_ease(Tween.EASE_IN)

	get_tree().create_timer(0.65).timeout.connect(
		func(): if is_instance_valid(effect): effect.queue_free()
	)

func _on_left_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_left_tab_clicked()

func _on_right_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_right_tab_clicked()

func _on_left_tab_clicked() -> void:
	if left_open:
		_slide_left_close()
	else:
		_slide_left_open()
	left_open = !left_open

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
	if _left_blood_label:
		_left_blood_label.text = str(new_value)

func _on_special_changed(new_value: float) -> void:
	var special_value: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox.get_node_or_null("SpecialRow/SpecialValue")
	if special_value:
		special_value.text = str(int(new_value))

func _on_chip_changed(new_value: int) -> void:
	var chip_value: Label = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow/ChipValue
	if chip_value:
		chip_value.text = str(new_value)
	var row: Control = $CanvasLayer/LeftPanel/Card1_Resources/ResourcesVBox/ChipRow
	row.modulate = Color(1, 1, 1, 0.5 if new_value <= 0 else 1.0)

func _on_blood_counter_tween_update(val: float) -> void:
	_displayed_blood = val
	if _blood_counter_ref and is_instance_valid(_blood_counter_ref):
		_blood_counter_ref.text = "🩸 %d" % int(val)

func _animate_blood_counter(amount: float, do_scale: bool) -> void:
	if not _blood_counter_ref or not is_instance_valid(_blood_counter_ref):
		return

	# 기존 tween 킬 + displayed_blood 즉시 동기화
	if _blood_anim_tween:
		_blood_anim_tween.kill()
		_blood_anim_tween = null

	# displayed_blood 를 현재 표시 중인 값으로 고정
	if _blood_counter_ref and is_instance_valid(_blood_counter_ref):
		_displayed_blood = float(_blood_counter_ref.text.replace("🩸 ", "").to_float())

	_blood_counter_ref.pivot_offset = _blood_counter_ref.size / 2
	_blood_anim_tween = create_tween()
	_blood_anim_tween.tween_method(
		_on_blood_counter_tween_update, _displayed_blood, amount, 0.35
	)
	if do_scale:
		_blood_anim_tween.tween_property(
			_blood_counter_ref, "scale", Vector2(1.3, 1.3), 0.15
		)
		_blood_anim_tween.tween_property(
			_blood_counter_ref, "scale", Vector2(1.0, 1.0), 0.1
		)

func update_blood_ui(amount: float) -> void:
	_blood_label.visible = false
	var diff: float = abs(amount - _last_blood_value) if _last_blood_value >= 0 else 0.0
	var do_scale: bool = diff >= 5.0
	_last_blood_value = amount
	_animate_blood_counter(amount, do_scale)
	if _left_blood_label:
		_left_blood_label.text = str(int(amount))

func _update_slot_count_label() -> void:
	var used: int = get_tree().get_nodes_in_group("game_nodes").size()
	var label: Label = $CanvasLayer/LeftPanel/NodeHeader
	if label:
		label.text = "배치 %d / %d" % [used, _unlocked_slots]
		if used >= _unlocked_slots:
			label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		else:
			label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5))

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
