extends Node

signal resource_changed(type: String, new_value: Variant)

var blood: float = 0.0
var special: float = 0.0
var node_fragments: int = 0


func _ready() -> void:
	print("ResourceManager 시작")
	pass


## SynergyEngine에서 시너지 발동 시 호출됨
func apply_synergy_effect(synergy: Dictionary, effect_data: Dictionary, position: Vector2) -> void:
	pass


func add_blood(amount: float) -> void:
	blood += amount
	resource_changed.emit("blood", blood)
	# TopBar 재화 표시 업데이트
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.update_blood_ui(blood)


func add_resource(type: String, amount: float) -> void:
	match type:
		"blood":
			blood += amount
			resource_changed.emit("blood", blood)
		"special":
			special += amount
			resource_changed.emit("special", special)
		"node":
			node_fragments += int(amount)
			resource_changed.emit("node", node_fragments)


func spend_blood(amount: float) -> bool:
	if blood < amount:
		return false
	blood -= amount
	resource_changed.emit("blood", blood)
	return true


func spend_special(amount: float) -> bool:
	if special < amount:
		return false
	special -= amount
	resource_changed.emit("special", special)
	return true


func get_all() -> Dictionary:
	return {
		"blood": blood,
		"special": special,
		"node": node_fragments
	}
