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
		n.attack_cooldown = 3.0 if n.node_type != "흡혈" else 2.0
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
			absorb.attack_cooldown = 1.0  # 흡혈 기본 2초의 50%

	if types.has("결계") and types.has("증폭"):
		var freeze = a if a.node_type == "결계" else b
		freeze.synergy_wide_slow = true
