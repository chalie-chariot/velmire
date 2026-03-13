class_name SynergyEngine
extends Node

signal synergy_activated(synergy_id: String, effect_data: Dictionary)
signal new_synergy_discovered(synergy_id: String)

var _synergy_table: Array = []
var _discovered_synergies: Dictionary = {}
var _active_synergies: Array = []


func _ready() -> void:
	print("SynergyEngine 시작")
	_load_synergy_table()
	_connect_to_connection_source()


func _load_synergy_table() -> void:
	var file: FileAccess = FileAccess.open("res://data/synergy_table.json", FileAccess.READ)
	if not file:
		push_error("SynergyEngine: synergy_table.json 로드 실패")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		push_error("SynergyEngine: synergy_table.json 파싱 실패")
		return
	_synergy_table = data if data is Array else []


func _connect_to_connection_source() -> void:
	var node_grid: Node = _find_node_grid()
	if node_grid and node_grid.has_signal("connection_made"):
		node_grid.connection_made.connect(_on_connection_made)
		return
	var connection_manager: Node = _find_connection_manager()
	if connection_manager and connection_manager.has_signal("connection_made"):
		connection_manager.connection_made.connect(_on_connection_made)


func _find_node_grid() -> Node:
	return _find_node_of_type("NodeGrid")


func _find_connection_manager() -> Node:
	return _find_node_of_type("ConnectionManager")


func _find_node_of_type(type_name: String) -> Node:
	var root: Node = get_tree().root
	return _find_node_recursive(root, type_name)


func _find_node_recursive(node: Node, type_name: String) -> Node:
	var script: Script = node.get_script()
	if script is GDScript:
		if (script as GDScript).get_global_name() == type_name:
			return node
	for child: Node in node.get_children():
		var found: Node = _find_node_recursive(child, type_name)
		if found:
			return found
	return null


func _on_connection_made(node_a: String, node_b: String) -> void:
	var synergy: Dictionary = check_synergy(node_a, node_b)
	if synergy.is_empty():
		return
	activate_synergy(synergy, Vector2.ZERO)


## A+B 조합이 synergy_table에 있으면 해당 시너지 Dictionary 반환, 없으면 {}
func check_synergy(node_a_id: String, node_b_id: String) -> Dictionary:
	for entry: Dictionary in _synergy_table:
		var na: String = entry.get("node_a", "")
		var nb: String = entry.get("node_b", "")
		if (na == node_a_id and nb == node_b_id) or (na == node_b_id and nb == node_a_id):
			return entry
	return {}


## 시너지 이펙트 신호 발생, ResourceManager에 효과 통보
func activate_synergy(synergy: Dictionary, position: Vector2) -> void:
	if synergy.is_empty():
		return
	
	var synergy_id: String = synergy.get("id", "")
	var effect_data: Dictionary = {
		"synergy": synergy,
		"position": position,
		"name": synergy.get("name", ""),
		"effect": synergy.get("effect", ""),
		"color": synergy.get("color", "#FFFFFF")
	}
	
	if not _discovered_synergies.has(synergy_id):
		_discovered_synergies[synergy_id] = true
		new_synergy_discovered.emit(synergy_id)
	
	_active_synergies.append({
		"id": synergy_id,
		"synergy": synergy,
		"position": position,
		"effect_data": effect_data
	})
	
	synergy_activated.emit(synergy_id, effect_data)
	_notify_resource_manager(synergy, effect_data, position)


func _notify_resource_manager(synergy: Dictionary, effect_data: Dictionary, position: Vector2) -> void:
	var rm: Node = _find_node_of_type("ResourceManager") as Node
	if rm and rm.has_method("apply_synergy_effect"):
		rm.apply_synergy_effect(synergy, effect_data, position)


## 현재 활성화된 모든 시너지 반환
func get_active_synergies() -> Array:
	return _active_synergies.duplicate()


func clear_active_synergies() -> void:
	_active_synergies.clear()
