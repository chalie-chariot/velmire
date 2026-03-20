extends CanvasLayer

@onready var btn_stage: Button = $MenuButtons/Btn_Stage
@onready var btn_battle: Button = $MenuButtons/Btn_Battle

func _ready() -> void:
	btn_stage.pressed.connect(_on_stage)
	btn_battle.pressed.connect(_on_battle)

func _on_stage() -> void:
	get_tree().change_scene_to_file("res://scenes/StageMain.tscn")

func _on_battle() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
