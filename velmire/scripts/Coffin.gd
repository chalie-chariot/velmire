extends Node2D

## Coffin Node2D - group "coffin"
## CoffinBase, CoffinRose, Crack1(6), Crack2(9), ShardRoot

@export var size: Vector2 = Vector2(80, 120)

@onready var coffin_base: Sprite2D = $CoffinBase
@onready var coffin_rose: Sprite2D = $CoffinRose
@onready var crack1: Node2D = $Crack1
@onready var crack2: Node2D = $Crack2
@onready var shard_root: Node2D = $ShardRoot
var _shatter_played: bool = false
var _shards_settled: bool = false  # scatter 연출 종료 후 glow 적용
var _shard_sprites: Array[Sprite2D] = []
var _shard_glow_state: Dictionary = {}  # Sprite2D -> "dark"|"fade_in"|"glow"|"fade_out"|"passed"
var _shard_tweens: Dictionary = {}  # Sprite2D -> Tween

const SHARD_MOD_DARK := Color(0.6, 0.1, 0.1)
const SHARD_MOD_GLOW := Color(1.2, 0.3, 0.3)
const GLOW_PASS_THRESHOLD: float = 100.0  # pulse front 지나간 거리 → fade out


func _ready() -> void:
	add_to_group("coffin")
	process_mode = Node.PROCESS_MODE_ALWAYS  # 게임오버 시 퍼즈되어도 shatter 연출 재생
	var hp = get_tree().get_first_node_in_group("heart_pulse")
	if hp and hp.has_signal("pulse_started"):
		hp.pulse_started.connect(_on_pulse_started)
	if coffin_base and coffin_base.texture:
		size = coffin_base.texture.get_size() * scale
	crack1.visible = false
	crack2.visible = false


func update_crack_visibility(hp_ratio: float) -> void:
	crack1.visible = hp_ratio <= 0.5
	crack2.visible = hp_ratio <= 0.2


func _on_pulse_started() -> void:
	for sprite in _shard_sprites:
		if not is_instance_valid(sprite):
			continue
		if sprite in _shard_tweens and _shard_tweens[sprite]:
			_shard_tweens[sprite].kill()
		_shard_glow_state[sprite] = "dark"
		sprite.modulate = SHARD_MOD_DARK


func _process(_delta: float) -> void:
	if not _shatter_played or not _shards_settled or _shard_sprites.is_empty():
		return
	var hp = get_tree().get_first_node_in_group("heart_pulse")
	if not hp or not hp.is_pulsing():
		return
	var center: Vector2 = hp.get_pulse_center()
	var radius: float = hp.get_pulse_radius()
	for sprite in _shard_sprites:
		if not is_instance_valid(sprite):
			continue
		var dist: float = center.distance_to(sprite.global_position)
		var state: String = _shard_glow_state.get(sprite, "dark")
		# 거리 <= radius: 파동 안쪽
		if dist <= radius:
			var passed: float = radius - dist
			if state == "dark":
				# 진입 → fade in
				if sprite in _shard_tweens and _shard_tweens[sprite]:
					_shard_tweens[sprite].kill()
				var tw := create_tween()
				_shard_tweens[sprite] = tw
				tw.tween_property(sprite, "modulate", SHARD_MOD_GLOW, 0.15).set_ease(Tween.EASE_OUT)
				tw.tween_callback(func() -> void:
					_shard_glow_state[sprite] = "glow"
					_shard_tweens.erase(sprite)
				)
				_shard_glow_state[sprite] = "fade_in"
			elif state == "glow" and passed > GLOW_PASS_THRESHOLD:
				# 파동 지나감 → fade out
				if sprite in _shard_tweens and _shard_tweens[sprite]:
					continue
				var tw := create_tween()
				_shard_tweens[sprite] = tw
				tw.tween_property(sprite, "modulate", SHARD_MOD_DARK, 0.3).set_ease(Tween.EASE_OUT)
				tw.tween_callback(func() -> void:
					_shard_glow_state[sprite] = "passed"  # 이번 맥박에서 재발광 방지
					_shard_tweens.erase(sprite)
				)
				_shard_glow_state[sprite] = "fade_out"


func play_game_over_shatter() -> void:
	if _shatter_played:
		return
	_shatter_played = true

	# 1. CoffinRose 글로우 Tween으로 어둡게 전환 (0.3초)
	coffin_rose.modulate = Color(2.0, 0.1, 0.1)
	var rose_tw = create_tween()
	rose_tw.tween_property(coffin_rose, "modulate",
		Color(0.15, 0.05, 0.05), 0.3
	).set_ease(Tween.EASE_IN)

	# 2. Crack1 + Crack2 전체 15개 조각 사방 튕김 (튕긴 자리에 유지, 사라지지 않음)
	_shards_settled = false
	get_tree().create_timer(1.0).timeout.connect(func() -> void: _shards_settled = true)
	crack1.visible = true
	crack2.visible = true
	_shard_sprites.clear()
	for child in crack1.get_children():
		if child is Sprite2D:
			_shard_sprites.append(child)
	for child in crack2.get_children():
		if child is Sprite2D:
			_shard_sprites.append(child)
	var all_sprites: Array[Sprite2D] = _shard_sprites

	# 특별 파편 2개: 15개 중 랜덤 선택 → 먼 거리
	var indices: Array = []
	for i in all_sprites.size():
		indices.append(i)
	indices.shuffle()
	var special_indices: Dictionary = {indices[0]: true, indices[1]: true}

	# CoffinBase는 그대로 유지 (사라지지 않음)
	var base_pos := global_position
	for i in all_sprites.size():
		var sprite: Sprite2D = all_sprites[i]
		var spr_pos: Vector2 = sprite.global_position
		var dir: Vector2 = (spr_pos - base_pos).normalized()
		if dir.is_zero_approx():
			dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		dir += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		dir = dir.normalized()
		var dist: float = randf_range(800.0, 1100.0) if special_indices.has(i) else randf_range(180.0, 320.0)
		var target_pos: Vector2 = spr_pos + dir * dist
		var dur: float = randf_range(0.6, 0.8)

		# 최종 scale 랜덤 (이동 끝날 때 고정)
		var flip_x: bool = randf() > 0.5
		var flip_y: bool = randf() > 0.5
		if not flip_x and not flip_y:
			flip_x = true
		var final_scale := Vector2(-1 if flip_x else 1, -1 if flip_y else 1)

		# Tween 하나로: position + scale.y(속도 연동 flip) + modulate(거리별 어둡기) 동시 제어
		# progress 0→1에 TRANS_QUAD EASE_OUT → 처음엔 빠르게, 끝에 가까울수록 느려짐
		var flip_count: int = int(dur * 14)  # 이동 속도에 비례한 flip 횟수
		flip_count = clampi(flip_count, 4, 16)
		var mod_dark := Color(0.15, 0.15, 0.15, 1)  # 비행 중 어둡기
		var tw = create_tween()
		tw.tween_method(func(p: float) -> void:
			# position
			sprite.global_position = spr_pos.lerp(target_pos, p)
			# scale.y: progress 기반 flip (속도에 비례 - EASE_OUT이라 초반에 많이 flip)
			var flips := int(p * flip_count)
			var sy: float = -1.0 if (flips % 2 == 1) else 1.0
			sprite.scale = Vector2(1.0, sy)  # 비행 중엔 scale.x=1, y만 flip
			# modulate: 거리(진행도)에 따라 어두워짐 (alpha 1.0 유지)
			sprite.modulate = Color.WHITE.lerp(mod_dark, p)
		, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# 끝나면 마지막 scale 고정 + 발광용 어두운 상태로
		tw.tween_callback(func() -> void:
			sprite.scale = final_scale
			sprite.modulate = SHARD_MOD_DARK
		)

	# 3. 파편 튕김 완료 직후 CoffinBase 서서히 어둡게 (3초 대기 중)
	get_tree().create_timer(0.85).timeout.connect(func() -> void:
		var base_tw := create_tween()
		base_tw.tween_property(coffin_base, "modulate", Color(0.1, 0.1, 0.1, 1), 2.5
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
