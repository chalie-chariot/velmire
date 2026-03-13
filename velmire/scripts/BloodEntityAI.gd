class_name BloodEntityAI
extends CharacterBody2D

signal entity_died(drop_type: String, drop_amount: int, death_position: Vector2)

@export var entity_data: Dictionary = {}

var _max_hp: float = 30.0
var _current_hp: float = 30.0
var _coffin_target: Node2D = null
var _resistance: String = ""


func _ready() -> void:
	print("BloodEntity 시작")
	_apply_entity_data()
	_find_coffin()
	_generate_circle_texture()
	_update_health_bar()


func _apply_entity_data() -> void:
	if entity_data.is_empty():
		return
	_max_hp = float(entity_data.get("hp", 30))
	_current_hp = _max_hp
	_resistance = str(entity_data.get("resistance", ""))
	var speed_val: float = float(entity_data.get("speed", 60))
	# CharacterBody2D does not have speed property - we use velocity
	# Store in meta for use in _physics_process
	set_meta("move_speed", speed_val)
	var radius_val: float = float(entity_data.get("radius", 20))
	var collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		(collision.shape as CircleShape2D).radius = radius_val
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite and entity_data.has("color"):
		sprite.modulate = Color.from_string(str(entity_data.get("color", "#CC0000")), Color.RED)


func _find_coffin() -> void:
	var coffin: Node = _find_node_of_type("Coffin")
	if coffin == null:
		coffin = get_tree().get_first_node_in_group("coffin")
	if coffin == null:
		coffin = _find_node_by_name("Coffin")
	if coffin is Node2D:
		_coffin_target = coffin as Node2D


func _find_node_by_name(node_name: String) -> Node:
	var root: Node = get_tree().root
	return _find_node_by_name_recursive(root, node_name)


func _find_node_by_name_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_node_by_name_recursive(child, node_name)
		if found:
			return found
	return null


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


func _generate_circle_texture() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	var radius: float = float(entity_data.get("radius", 20))
	var size: int = int(radius * 2)
	if size < 4:
		size = 4
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	for y in range(size):
		for x in range(size):
			var pt: Vector2 = Vector2(x, y)
			if pt.distance_to(center) <= radius:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	sprite.texture = tex
	var col_str: String = str(entity_data.get("color", "#CC0000"))
	sprite.modulate = Color.from_string(col_str, Color.RED)


func _physics_process(delta: float) -> void:
	if _coffin_target == null:
		_find_coffin()
	if _coffin_target == null:
		return
	var speed: float = float(get_meta("move_speed", 60))
	var dir: Vector2 = (_coffin_target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()


func _update_health_bar() -> void:
	var bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
	if not bar:
		return
	bar.visible = _current_hp < _max_hp and _max_hp > 0
	bar.max_value = _max_hp
	bar.value = _current_hp
	var radius: float = float(entity_data.get("radius", 20))
	bar.offset_left = -radius
	bar.offset_right = radius
	bar.offset_top = -radius - 10
	bar.offset_bottom = -radius - 4


## 피해 적용. damage_type이 resistance와 일치하면 0 처리
func take_damage(amount: float, damage_type: String) -> void:
	if _resistance != "" and damage_type == _resistance:
		return
	_current_hp -= amount
	_update_health_bar()
	if _current_hp <= 0:
		_die()


func _die() -> void:
	var drop_type: String = str(entity_data.get("drop", "blood"))
	var drop_amount: int = int(entity_data.get("drop_amount", 1))
	if drop_amount <= 0:
		drop_amount = 1
	entity_died.emit(drop_type, drop_amount, global_position)
	queue_free()
