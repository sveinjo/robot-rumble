extends CanvasLayer

const DEFAULT_SPAWN_INTERVAL := 20.0 / 60.0

var enabled: bool = true
var spawn_interval: float = DEFAULT_SPAWN_INTERVAL
var spawn_timer: float = DEFAULT_SPAWN_INTERVAL

var particle_star1_scene = preload("res://scenes/particle_star1.tscn")
var particle_star2_scene = preload("res://scenes/particle_star2.tscn")
var particle_star3_scene = preload("res://scenes/particle_star3.tscn")

var container: Node2D
var debug_sample_timer: float = 0.0
var last_star_counts: Dictionary = {
	"fast": 0,
	"mid": 0,
	"slow": 0,
	"total": 0
}

func _ready():
	layer = -1
	container = Node2D.new()
	container.name = "StarContainer"
	add_child(container)
	spawn_timer = spawn_interval
	debug_sample_timer = 0.0

func _process(delta: float):
	debug_sample_timer -= delta
	if debug_sample_timer <= 0.0:
		last_star_counts = _count_star_types()
		debug_sample_timer = 0.25

	if not enabled:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	_create_star_particle()
	spawn_timer = max(0.01, spawn_interval)

func _create_star_particle():
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var star_line := randf() * viewport_size.y
	var star_type := randf() * 3.0
	var particle_scene: PackedScene

	if star_type > 2.0:
		particle_scene = particle_star3_scene
	elif star_type > 1.0:
		particle_scene = particle_star2_scene
	else:
		particle_scene = particle_star1_scene

	var particle: Node2D = particle_scene.instantiate()
	particle.position = Vector2(viewport_size.x, star_line)
	container.add_child(particle)

func set_enabled(value: bool):
	enabled = value

func set_spawn_interval(value: float):
	spawn_interval = max(0.01, value)

func clear_particles():
	for child in container.get_children():
		child.queue_free()

func reset_defaults():
	enabled = true
	spawn_interval = DEFAULT_SPAWN_INTERVAL
	spawn_timer = spawn_interval

func get_star_type_counts() -> Dictionary:
	return last_star_counts

func _count_star_types() -> Dictionary:
	var fast := 0
	var mid := 0
	var slow := 0

	for child in container.get_children():
		if not child.has_method("get"):
			continue
		var mult: int = int(child.get("speed_multiplier"))
		if mult >= 4:
			fast += 1
		elif mult >= 2:
			mid += 1
		else:
			slow += 1

	return {
		"fast": fast,
		"mid": mid,
		"slow": slow,
		"total": fast + mid + slow
	}
