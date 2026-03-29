extends Node2D

const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_SIZE := Vector2(176, 176)
const ROSTER_X := 15.0
const ROSTER_Y: Array[int] = [0, 68, 260, 452, 644, 836]
const GRID_X: Array[int] = [0, 913, 1238, 1563]
const GRID_Y: Array[int] = [0, 143, 452, 761]
const HEADING_POS := Vector2(865, 44)
const CANCEL_RECT := Rect2(Vector2(1798, 0), Vector2(122, 88))

var arcade_font: Font
var frame_texture: Texture2D
var flare_texture: Texture2D
var hero_textures: Dictionary = {}

var particle_star1_scene = preload("res://scenes/particle_star1.tscn")
var particle_star2_scene = preload("res://scenes/particle_star2.tscn")
var particle_star3_scene = preload("res://scenes/particle_star3.tscn")

var star_timer: float = 0.10

var tiles: Array[Dictionary] = [
	{"caption": "CARBS", "value": "10", "hero": false},
	{"caption": "PROTEIN", "value": "20", "hero": false},
	{"caption": "FATS", "value": "30", "hero": false},
	{"caption": "FAST INSULIN", "value": "3", "hero": false},
	{"caption": "", "value": "", "hero": true},
	{"caption": "SLOW INSULIN", "value": "6", "hero": false}
]

func _ready():
	randomize()
	Global.ensure_ported_data()
	arcade_font = Global.arcade_font if Global.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	flare_texture = load("res://assets/sprites/Flare.png")
	_load_hero_textures()
	_setup_ambient_fx()
	_update_layout_to_viewport()
	queue_redraw()

func _load_hero_textures():
	for i in range(1, 6):
		var raw_hero: Variant = Global.arrayHeroes[i]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if hero.has("texture_path"):
			hero_textures[i] = load(str(hero["texture_path"]))

func _setup_ambient_fx():
	var marker := Sprite2D.new()
	marker.position = Vector2(1326, 540)
	marker.texture = flare_texture
	marker.script = load("res://scripts/marker.gd")
	marker.z_index = 20
	add_child(marker)

	var marker2 := Sprite2D.new()
	marker2.position = Vector2(1326, 540)
	marker2.texture = flare_texture
	marker2.script = load("res://scripts/marker2.gd")
	marker2.z_index = 20
	add_child(marker2)

func _update_layout_to_viewport():
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = min(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	scale = Vector2(fit_scale, fit_scale)
	position = (viewport_size - (DESIGN_SIZE * fit_scale)) * 0.5

func _process(delta: float):
	_update_layout_to_viewport()
	_update_starfield(delta)
	queue_redraw()

func _update_starfield(delta: float):
	star_timer -= delta
	if star_timer > 0.0:
		return
	star_timer = 20.0 / 60.0
	_create_star_particle()

func _create_star_particle():
	var star_line := randf() * 1080.0
	var t := randf() * 3.0
	var ps: PackedScene
	if t > 2.0:
		ps = particle_star3_scene
	elif t > 1.0:
		ps = particle_star2_scene
	else:
		ps = particle_star1_scene
	var p: Node2D = ps.instantiate()
	p.position = Vector2(1920, star_line)
	p.z_index = -50
	add_child(p)

func _input(event: InputEvent):
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var me: InputEventMouseButton = event

	if me.button_index == MOUSE_BUTTON_RIGHT:
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
		return

	if me.button_index != MOUSE_BUTTON_LEFT:
		return

	var local_p: Vector2 = to_local(me.position)
	if CANCEL_RECT.has_point(local_p):
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")

func _draw():
	_draw_heading()
	_draw_roster()
	_draw_tiles()
	_draw_cancel_button()

func _draw_heading():
	if arcade_font == null:
		return
	draw_string(arcade_font, HEADING_POS + Vector2(3, 3), "(HOME BASE NOT OPERATIONAL)", HORIZONTAL_ALIGNMENT_LEFT, 1040, 24, Color(0, 0, 1))
	draw_string(arcade_font, HEADING_POS, "(HOME BASE NOT OPERATIONAL)", HORIZONTAL_ALIGNMENT_LEFT, 1040, 24, Color.WHITE)

func _draw_roster():
	if arcade_font == null:
		return
	for hero_id in range(1, 6):
		var rect := Rect2(Vector2(ROSTER_X, ROSTER_Y[hero_id]), CARD_SIZE)
		var tex: Texture2D = hero_textures.get(hero_id, null)
		if tex != null:
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, 0.25))
		else:
			draw_rect(rect, Color(0.2, 0.2, 0.2, 0.75), true)
		if frame_texture != null:
			draw_texture_rect(frame_texture, rect, false)

		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var level := int(hero.get("intLevel", 1))
		var xp := int(hero.get("intXp", 0))
		var label := "%s  Lv%d  XP:%d" % [str(hero.get("class", "Hero")), level, xp]
		draw_string(arcade_font, rect.position + Vector2(204, 22), label, HORIZONTAL_ALIGNMENT_LEFT, 420, 16, Color.BLACK)

func _draw_tiles():
	if arcade_font == null:
		return
	var idx := 0
	for y in range(1, 3):
		for x in range(1, 4):
			var tile := tiles[idx]
			var rect := Rect2(Vector2(GRID_X[x], GRID_Y[y]), CARD_SIZE)
			if bool(tile.get("hero", false)):
				var center_tex: Texture2D = hero_textures.get(2, null)
				if center_tex != null:
					draw_texture_rect(center_tex, rect, false)
				else:
					draw_rect(rect, Color(0.2, 0.2, 0.2, 0.85), true)
			else:
				draw_rect(rect, Color(0.08, 0.08, 0.08, 0.85), true)
			if frame_texture != null:
				draw_texture_rect(frame_texture, rect, false)

			var caption := str(tile.get("caption", ""))
			var value := str(tile.get("value", ""))
			if caption != "":
				draw_string(arcade_font, rect.position + Vector2(88, 20), caption, HORIZONTAL_ALIGNMENT_CENTER, 176, 16, Color.WHITE)
				draw_string(arcade_font, rect.position + Vector2(88, 164), value, HORIZONTAL_ALIGNMENT_CENTER, 176, 16, Color.WHITE)
			idx += 1

func _draw_cancel_button():
	if arcade_font == null:
		return
	draw_rect(CANCEL_RECT, Color(0.2, 0.2, 0.2, 0.85), true)
	draw_rect(CANCEL_RECT, Color.WHITE, false, 2.0)
	draw_string(arcade_font, CANCEL_RECT.position + Vector2(12, 54), "CANCEL", HORIZONTAL_ALIGNMENT_LEFT, 110, 18, Color.WHITE)
