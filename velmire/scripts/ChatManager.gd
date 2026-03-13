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


## 채팅 메시지 추가
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


## 이벤트 타입에 따른 하드코딩/스크립트 채팅 트리거
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
