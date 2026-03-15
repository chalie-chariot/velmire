extends Node

signal resource_changed(type: String, new_value: Variant)
signal blood_changed(new_value: int)
signal special_changed(new_value: float)

var blood: int = 50  # 테스트용 초기값
var special: float = 0.0
var node_fragments: int = 0
var difficulty: int = 0  # 0단계부터 시작

# 누적 데이터 (Autoload라 reload_current_scene() 해도 유지됨)
var total_runs: int = 0
var total_kills: int = 0
var best_viewers: int = 0

var ruby: int = 0  # 블러디아 루비


func add_ruby(amount: int) -> void:
	ruby += amount
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("update_ruby_ui"):
		main.update_ruby_ui(ruby)


func spend_ruby(amount: int) -> bool:
	if ruby < amount:
		return false
	ruby -= amount
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("update_ruby_ui"):
		main.update_ruby_ui(ruby)
	return true


func _ready() -> void:
	print("ResourceManager 시작")
	pass


## SynergyEngine에서 시너지 발동 시 호출됨
func apply_synergy_effect(synergy: Dictionary, effect_data: Dictionary, position: Vector2) -> void:
	pass


func add_blood(amount) -> void:
	blood += int(amount)
	blood_changed.emit(blood)


func heal_coffin(amount: float) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("heal_coffin"):
		main.heal_coffin(amount)


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
	resource_changed.emit("special", special)
	special_changed.emit(special)
	return true


func get_all() -> Dictionary:
	return {
		"blood": blood,
		"special": special,
		"node": node_fragments
	}
