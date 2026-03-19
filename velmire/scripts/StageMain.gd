extends Node2D

# 루트 데이터 (기획 확정 전 임시값)
const ROUTE_DATA = [
	{
		"id": 0,
		"name": "혈도 I",
		"desc": "첫 번째 혈도.\n기본 침공 루트.",
		"stage_set": 0,   # 서브씬에서 사용할 카드 세트 인덱스
		"position": Vector2(-300, 0)   # GlobeBase 위 버튼 위치 (조정 필요)
	},
	{
		"id": 1,
		"name": "혈도 II",
		"desc": "두 번째 혈도.\n위협이 강화된 루트.",
		"stage_set": 1,
		"position": Vector2(0, -200)
	},
	{
		"id": 2,
		"name": "혈도 III",
		"desc": "세 번째 혈도.\n봉인된 자들이 깨어난다.",
		"stage_set": 2,
		"position": Vector2(300, 100)
	}
]

@onready var rm = get_tree().get_first_node_in_group("resource_manager")
@onready var hover_panel = $CanvasLayer/HoverInfoPanel
@onready var route_name_label = $CanvasLayer/HoverInfoPanel/VBoxContainer/RouteNameLabel
@onready var route_desc_label = $CanvasLayer/HoverInfoPanel/VBoxContainer/RouteDescLabel

func _ready():
	hover_panel.visible = false
	_setup_route_buttons()

func _setup_route_buttons():
	var buttons = [
		$EntityLayer/GlobeContainer/RouteButtons/RouteButton0,
		$EntityLayer/GlobeContainer/RouteButtons/RouteButton1,
		$EntityLayer/GlobeContainer/RouteButtons/RouteButton2
	]
	for i in buttons.size():
		var btn = buttons[i]
		btn.position = ROUTE_DATA[i]["position"]
		btn.mouse_entered.connect(_on_route_hover.bind(i))
		btn.mouse_exited.connect(_on_route_hover_exit)
		btn.pressed.connect(_on_route_select.bind(i))

func _on_route_hover(idx: int):
	route_name_label.text = ROUTE_DATA[idx]["name"]
	route_desc_label.text = ROUTE_DATA[idx]["desc"]
	hover_panel.visible = true

func _on_route_hover_exit():
	hover_panel.visible = false

func _on_route_select(idx: int):
	rm.selected_route = idx
	rm.set_meta("stage_set", ROUTE_DATA[idx]["stage_set"])
	get_tree().change_scene_to_file("res://scenes/StageSub.tscn")

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Main_Title.tscn")
