extends Node2D

# 관 주변에 항상 퍼지는 마젠타~붉은색 작은 파티클
var _particles: Array = []
var _center: Vector2 = Vector2.ZERO
var _spawn_timer: float = 0.0
const MAX_PARTICLES: int = 35
const SPAWN_INTERVAL: float = 0.18

func setup(coffin_center: Vector2) -> void:
	_center = coffin_center
	position = _center

func _process(delta: float) -> void:
	# 관 위치 동기화
	var coffin = get_tree().get_first_node_in_group("coffin")
	if coffin:
		_center = coffin.position + coffin.size / 2
		position = _center

	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL and _particles.size() < MAX_PARTICLES:
		_spawn_timer = 0.0
		_spawn_particle()

	var i: int = _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p.pos += p.vel * delta
		p.vel *= 0.96
		p.alpha -= 0.65 * delta
		if p.alpha <= 0:
			_particles.remove_at(i)
		i -= 1
	queue_redraw()

func _spawn_particle() -> void:
	var angle: float = randf_range(0, TAU)
	var dist: float = randf_range(40.0, 160.0)
	var pos: Vector2 = Vector2(cos(angle), sin(angle)) * dist
	var out_dir: Vector2 = pos.normalized()
	var spd: float = randf_range(40.0, 110.0)
	var vel: Vector2 = out_dir * spd + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	# 마젠타 ~ 붉은색
	var t: float = randf()
	var col: Color = Color(1.0, 0.1, 0.2 + t * 0.8, 0.0)  # red → magenta
	_particles.append({
		"pos": pos,
		"vel": vel,
		"size": randf_range(0.75, 2.0),
		"alpha": randf_range(0.5, 1.0),
		"color": col
	})

func _draw() -> void:
	for p in _particles:
		if p.alpha <= 0:
			continue
		var c: Color = p.color
		c.a = p.alpha
		draw_circle(p.pos, p.size, c)
