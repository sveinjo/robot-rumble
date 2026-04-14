@tool
extends Node2D

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const STAR_SPAWN_INTERVAL := 1.0 / 60.0
const STAR_SPEED_MULTIPLIERS: Array[int] = [4, 2, 1]
const DEFAULT_ANIMATION := "run"
const ALIEN_FALLBACK_TEXTURE: Texture2D = preload("res://assets/Spine/Alien/export/alien.png")
const ALIEN_SKELETON_CANDIDATES: Array[String] = [
	"res://assets/Spine/Alien/alien-ess.spine",
	"res://assets/Spine/Alien/alien-pro.spine",
	"res://assets/Spine/Alien/export/alien-ess.skel",
	"res://assets/Spine/Alien/export/alien-pro.skel",
	"res://assets/Spine/Alien/export/alien-ess.json",
	"res://assets/Spine/Alien/export/alien-pro.json",
]
const ALIEN_ATLAS_CANDIDATES: Array[String] = [
	"res://assets/Spine/Alien/export/alien.atlas",
	"res://assets/Spine/Alien/export/alien-pma.atlas",
]
const STAR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/Star1d_0.png"),
	preload("res://assets/sprites/Star2d_0.png"),
	preload("res://assets/sprites/Star3d_0.png"),
]

@onready var stars_root: Node2D = $Stars
@onready var alien_spine: Node = $AlienSpine
@onready var animation_label: Label = null

@export var show_starfield: bool = true
@export var star_spawn_interval: float = STAR_SPAWN_INTERVAL
@export var star_speed: float = 2.0
@export var star_size: float = 1.0

var _idle_time := 0.0
var _star_rng := RandomNumberGenerator.new()
var _star_spawn_timer: float = STAR_SPAWN_INTERVAL

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_process_input(false)
		return

	_setup_starfield()
	set_process(true)
	set_process_input(true)
	_ensure_animation_label()
	_setup_alien_visual()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_starfield(delta)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TAB:
			_next_animation()

func _setup_starfield() -> void:
	if stars_root == null:
		return

	_star_rng.randomize()
	_star_spawn_timer = maxf(0.01, star_spawn_interval)
	stars_root.z_index = -5
	_clear_starfield()
	stars_root.visible = show_starfield
	if not show_starfield:
		return

func _spawn_star(spawn_at_random_x: bool = false) -> void:
	if stars_root == null:
		return

	var star_tier: int = _star_rng.randi_range(0, 2)
	var speed_multiplier: float = STAR_SPEED_MULTIPLIERS[star_tier]

	var star := Sprite2D.new()
	star.texture = STAR_TEXTURES[star_tier]
	star.z_index = 10 if star_tier == 0 else 0
	star.scale = Vector2(star_size, star.scale.y)
	star.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	if spawn_at_random_x:
		star.position = Vector2(_star_rng.randf_range(0.0, viewport_size.x), _star_rng.randf_range(0.0, viewport_size.y))
	else:
		star.position = Vector2(viewport_size.x, _star_rng.randf_range(0.0, viewport_size.y))
	star.set_meta("speed_multiplier", speed_multiplier)
	stars_root.add_child(star)

func _update_starfield(delta: float) -> void:
	if stars_root == null:
		return

	if not show_starfield:
		stars_root.visible = false
		return

	stars_root.visible = true
	if star_speed < 14.0:
		star_speed = min(14.0, star_speed * 1.05)
	if star_size < 10.0:
		star_size = min(10.0, star_size * 1.05)

	_star_spawn_timer -= delta
	var safe_interval: float = maxf(0.01, star_spawn_interval)
	while _star_spawn_timer <= 0.0:
		_spawn_star(false)
		_star_spawn_timer += safe_interval

	var step_scale: float = delta * 60.0
	for star in stars_root.get_children():
		if not (star is Sprite2D):
			continue
		var star_sprite := star as Sprite2D
		var speed_multiplier: int = int(star_sprite.get_meta("speed_multiplier", 1))
		star_sprite.position.x += -star_speed * float(speed_multiplier) * step_scale
		star_sprite.scale.x = star_size
		var texture_width: float = float(star_sprite.texture.get_width()) if star_sprite.texture != null else 0.0
		if star_sprite.position.x <= -texture_width:
			star_sprite.queue_free()

func _clear_starfield() -> void:
	for child in stars_root.get_children():
		child.queue_free()

func _setup_alien_visual() -> void:
	if alien_spine == null:
		push_warning("[spine-debug] AlienSpine node is null")
		return

	var data_res: Resource = _build_spine_data_resource()
	if data_res != null:
		if _assign_spine_data(data_res):
			_play_animation(DEFAULT_ANIMATION)
			_dump_spine_animation_info()
			return
		push_warning("[spine-debug] Built SpineSkeletonDataResource but failed to assign it to AlienSpine")

	# Fallback: show static Alien image if Spine data fails to load.
	var fallback := alien_spine.get_node_or_null("AlienFallback") as Sprite2D
	if fallback == null:
		fallback = Sprite2D.new()
		fallback.name = "AlienFallback"
		alien_spine.add_child(fallback)
	fallback.texture = ALIEN_FALLBACK_TEXTURE
	fallback.position = Vector2(0, -120)
	fallback.scale = Vector2(2.0, 2.0)
	_set_animation_label(&"fallback")
	push_warning("[spine-debug] Using static fallback image because no valid Spine skeleton+atlas pair could be initialized")

func _build_spine_data_resource() -> Resource:
	if not ClassDB.class_exists("SpineSkeletonFileResource"):
		return null
	if not ClassDB.class_exists("SpineAtlasResource"):
		return null
	if not ClassDB.class_exists("SpineSkeletonDataResource"):
		return null

	for skeleton_path in ALIEN_SKELETON_CANDIDATES:
		var skeleton_fs_path := ProjectSettings.globalize_path(skeleton_path)
		var skeleton_file_res := ClassDB.instantiate("SpineSkeletonFileResource")
		if skeleton_file_res == null:
			print("[spine-debug] Failed to instantiate SpineSkeletonFileResource")
			continue
		if not skeleton_file_res.has_method("load_from_file"):
			print("[spine-debug] SpineSkeletonFileResource has no load_from_file method")
			continue
		var skeleton_ok := _call_loader_ok(skeleton_file_res, "load_from_file", skeleton_fs_path)
		print("[spine-debug] skeleton load: %s => %s" % [skeleton_fs_path, skeleton_ok])
		if not skeleton_ok:
			continue

		for atlas_path in ALIEN_ATLAS_CANDIDATES:
			var atlas_fs_path := ProjectSettings.globalize_path(atlas_path)
			var atlas_res := ClassDB.instantiate("SpineAtlasResource")
			if atlas_res == null:
				print("[spine-debug] Failed to instantiate SpineAtlasResource")
				continue
			if not atlas_res.has_method("load_from_atlas_file"):
				print("[spine-debug] SpineAtlasResource has no load_from_atlas_file method")
				continue
			var atlas_ok := _call_loader_ok(atlas_res, "load_from_atlas_file", atlas_fs_path)
			print("[spine-debug] atlas load: %s => %s" % [atlas_fs_path, atlas_ok])
			if not atlas_ok:
				continue

			var skeleton_data_res := ClassDB.instantiate("SpineSkeletonDataResource")
			if skeleton_data_res == null:
				print("[spine-debug] Failed to instantiate SpineSkeletonDataResource")
				continue
			skeleton_data_res.set("skeleton_file_res", skeleton_file_res)
			skeleton_data_res.set("atlas_res", atlas_res)
			print("[spine-debug] built skeleton data from %s + %s" % [skeleton_fs_path, atlas_fs_path])
			if skeleton_data_res is Resource:
				return skeleton_data_res as Resource
	return null

func _assign_spine_data(data_res: Resource) -> bool:
	if alien_spine == null or data_res == null:
		return false

	if alien_spine.has_method("set_skeleton_data_res"):
		alien_spine.call("set_skeleton_data_res", data_res)
		print("[spine-debug] assigned via method: set_skeleton_data_res")
		return true
	if alien_spine.has_method("set_skeleton_data_resource"):
		alien_spine.call("set_skeleton_data_resource", data_res)
		print("[spine-debug] assigned via method: set_skeleton_data_resource")
		return true

	var candidate_properties: Array[StringName] = [&"skeleton_data_res", &"skeleton_data_resource", &"skeleton_data"]
	for prop_name in candidate_properties:
		if _node_has_property(alien_spine, prop_name):
			alien_spine.set(String(prop_name), data_res)
			print("[spine-debug] assigned via property: %s" % String(prop_name))
			return true

	print("[spine-debug] no compatible skeleton-data method/property found on AlienSpine")
	return false

func _dump_spine_animation_info() -> void:
	if alien_spine == null:
		return
	if not alien_spine.has_method("get_animation_state"):
		print("[spine-debug] AlienSpine has no get_animation_state method")
		return
	if not alien_spine.has_method("get_animation_names"):
		print("[spine-debug] AlienSpine has no get_animation_names method")
		return
	var names: Variant = alien_spine.call("get_animation_names")
	print("[spine-debug] available animations: %s" % [names])

func _call_loader_ok(target: Object, method_name: String, path: String) -> bool:
	if target == null:
		return false
	if not target.has_method(method_name):
		return false
	var result: Variant = target.call(method_name, path)
	if typeof(result) == TYPE_NIL:
		return true
	if typeof(result) == TYPE_BOOL:
		return bool(result)
	if typeof(result) == TYPE_INT:
		return int(result) == OK
	return true

func _ensure_animation_label() -> void:
	if Engine.is_editor_hint():
		return
	var hud := get_node_or_null("AnimationHud") as CanvasLayer
	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "AnimationHud"
		add_child(hud)
	var label := hud.get_node_or_null("AnimationLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "AnimationLabel"
		hud.add_child(label)
		label.position = Vector2(12, 10)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 2)
	animation_label = label
	_set_animation_label(&"-")

func _set_animation_label(animation_name: StringName) -> void:
	if animation_label == null:
		return
	animation_label.text = "Animation: %s" % String(animation_name)

func _next_animation() -> void:
	if alien_spine == null:
		return
	_play_animation(DEFAULT_ANIMATION)
	print("[fight_room_skeleton2d_direct_spine] Animation: %s" % DEFAULT_ANIMATION)

func _play_animation(animation_name: String) -> void:
	if alien_spine == null:
		print("[spine-debug] cannot play animation, AlienSpine is null")
		return
	if alien_spine.has_method("get_animation_state"):
		var animation_state: Object = alien_spine.call("get_animation_state")
		if animation_state != null and animation_state.has_method("set_animation"):
			animation_state.call("set_animation", animation_name, true, 0)
			print("[spine-debug] set_animation('%s') succeeded" % animation_name)
		else:
			print("[spine-debug] animation_state missing or has no set_animation")
	else:
		print("[spine-debug] AlienSpine has no get_animation_state")
	_set_animation_label(StringName(animation_name))

func _node_has_property(target: Object, property_name: StringName) -> bool:
	if target == null:
		return false
	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == String(property_name):
			return true
	return false
