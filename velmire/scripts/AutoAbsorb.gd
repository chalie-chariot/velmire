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
