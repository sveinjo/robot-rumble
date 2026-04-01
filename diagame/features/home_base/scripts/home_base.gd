extends Node2D

const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_SIZE := Vector2(176, 176)
const FRAME_SIZE := Vector2(197, 176)
const ROSTER_X := 15.0
const ROSTER_Y: Array[int] = [0, 68, 260, 452, 644, 836]
const GRID_X: Array[int] = [0, 913, 1238, 1563]
const GRID_Y: Array[int] = [0, 143, 452, 761]
const HEADING_POS := Vector2(865, 44)
const CANCEL_BUTTON_SIZE := Vector2(244, 54)
const CANCEL_BUTTON_POS := Vector2(1920 - 244, 0)
const CANCEL_RECT := Rect2(CANCEL_BUTTON_POS, CANCEL_BUTTON_SIZE)

var arcade_font: Font
var frame_texture: Texture2D
var empty_texture: Texture2D
var menu_bar_texture: Texture2D
var flare_texture: Texture2D
var hero_textures: Dictionary = {}

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
	GameState.ensure_ported_data()
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	empty_texture = load("res://assets/sprites/Empty_0.png")
	menu_bar_texture = load("res://assets/sprites/MenuBar_0.png")
	flare_texture = load("res://assets/sprites/Flare.png")
	GameState.set_starfield_enabled(true)
	GameState.set_starfield_spawn_interval(20.0 / 60.0)
	_load_hero_textures()
	_setup_ambient_fx()
	_update_layout_to_viewport()
	queue_redraw()

func _load_hero_textures():
	for i in range(1, 6):
		var raw_hero: Variant = GameState.arrayHeroes[i]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if hero.has("texture_path"):
			hero_textures[i] = load(str(hero["texture_path"]))

func _setup_ambient_fx():
	var marker := Sprite2D.new()
	marker.position = Vector2(1326, 540)
	marker.texture = flare_texture
	marker.script = load("res://core/fx/markers/marker.gd")
	marker.z_index = -10
	add_child(marker)

	var marker2 := Sprite2D.new()
	marker2.position = Vector2(1326, 540)
	marker2.texture = flare_texture
	marker2.script = load("res://core/fx/markers/marker2.gd")
	marker2.z_index = -10
	add_child(marker2)

func _update_layout_to_viewport():
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = min(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	scale = Vector2(fit_scale, fit_scale)
	position = (viewport_size - (DESIGN_SIZE * fit_scale)) * 0.5

func _process(_delta: float):
	_update_layout_to_viewport()
	queue_redraw()

func _input(event: InputEvent):
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var me: InputEventMouseButton = event

	if me.button_index == MOUSE_BUTTON_RIGHT:
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")
		return

	if me.button_index != MOUSE_BUTTON_LEFT:
		return

	var local_p: Vector2 = to_local(me.position)
	if CANCEL_RECT.has_point(local_p):
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

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
			var frame_rect := Rect2(rect.position, FRAME_SIZE)
			draw_texture_rect(frame_texture, frame_rect, false)

		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var level := int(hero.get("intLevel", 1))
		var xp := int(hero.get("intXp", 0))
		var ability_idx := int(hero.get("skillSlot1", 1))
		var ability_name := "Ability"
		if ability_idx > 0 and ability_idx < GameState.arrayAbilities.size() and GameState.arrayAbilities[ability_idx] != null:
			ability_name = str(GameState.arrayAbilities[ability_idx])
		var current_level_floor: int = int(GameState.arrayLevels[level]) if level < GameState.arrayLevels.size() else 0
		var next_level: int = int(GameState.arrayLevels[level + 1]) if level + 1 < GameState.arrayLevels.size() else xp + 1
		var current_level_xp: int = max(0, xp - current_level_floor)
		var level_delta: int = max(1, next_level - current_level_floor)
		var hero_class := str(hero.get("class", "Hero"))
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(164, 22), 24), "%d" % level, HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color.BLACK)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 22), 24), hero_class, HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 48), 24), "XP:%d/%d" % [current_level_xp, level_delta], HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 72), 24), ability_name, HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)

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
					if frame_texture != null:
						var hero_frame_rect := Rect2(rect.position, FRAME_SIZE)
						draw_texture_rect(frame_texture, hero_frame_rect, false)
				else:
					draw_texture_rect(empty_texture, rect, false)
			else:
				draw_texture_rect(empty_texture, rect, false)

			var caption := str(tile.get("caption", ""))
			var value := str(tile.get("value", ""))
			if caption != "":
				var caption_wrapped := _break_after_first_word(caption)
				_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(91, 8), 24), caption_wrapped, 24, 176, Color(0, 0, 1))
				_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(88, 5), 24), caption_wrapped, 24, 176, Color.WHITE)
				_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(91, 152), 24), value, 24, 176, Color(0, 0, 1))
				_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(88, 149), 24), value, 24, 176, Color.WHITE)
			idx += 1

func _draw_cancel_button():
	if arcade_font == null:
		return
	if menu_bar_texture != null:
		var center := CANCEL_RECT.position + (CANCEL_RECT.size * 0.5)
		draw_set_transform(center, 0.0, Vector2(-1, 1))
		draw_texture_rect(menu_bar_texture, Rect2(-CANCEL_RECT.size * 0.5, CANCEL_RECT.size), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_rect(CANCEL_RECT, Color(0.2, 0.2, 0.2, 0.85), true)
	var char_width: float = arcade_font.get_string_size("C", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var text_pos := _with_text_height(CANCEL_RECT.position + Vector2(char_width, 16), 24)
	draw_string(arcade_font, text_pos + Vector2(3, 3), "CANCEL", HORIZONTAL_ALIGNMENT_CENTER, 244, 24, Color(0, 0, 1))
	draw_string(arcade_font, text_pos, "CANCEL", HORIZONTAL_ALIGNMENT_CENTER, 244, 24, Color.WHITE)

func _with_text_height(pos: Vector2, font_size: int) -> Vector2:
	return pos + Vector2(0, float(font_size))

func _break_after_first_word(text: String) -> String:
	var split_index := text.find(" ")
	if split_index == -1:
		return text
	return text.substr(0, split_index) + "\n" + text.substr(split_index + 1)

func _draw_wrapped_text(font: Font, pos: Vector2, text: String, font_size: int, max_width: int, color: Color):
	var normalized_text := text.replace("\n", " \n ")
	var words := normalized_text.split(" ")
	var lines := []
	var current_line := ""

	for word in words:
		if word == "\n":
			if current_line.length() > 0:
				lines.append(current_line)
				current_line = ""
			continue
		var test_text := current_line + (" " if current_line.length() > 0 else "") + word
		var text_size := font.get_string_size(test_text, 0, max_width, font_size)
		if text_size.x > max_width and current_line.length() > 0:
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_text

	if current_line.length() > 0:
		lines.append(current_line)

	var line_height := float(font.get_height(font_size)) if font != null else float(font_size)
	var y_offset := 0.0
	for line in lines:
		draw_string(font, pos + Vector2(0, y_offset), line, 0, -1, font_size, color)
		y_offset += line_height

func _draw_centered_wrapped_text(font: Font, center_pos: Vector2, text: String, font_size: int, max_width: int, color: Color):
	var normalized_text := text.replace("\n", " \n ")
	var words := normalized_text.split(" ")
	var lines := []
	var current_line := ""

	for word in words:
		if word == "\n":
			if current_line.length() > 0:
				lines.append(current_line)
				current_line = ""
			continue
		var test_text := current_line + (" " if current_line.length() > 0 else "") + word
		var text_size := font.get_string_size(test_text, 0, max_width, font_size)
		if text_size.x > max_width and current_line.length() > 0:
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_text

	if current_line.length() > 0:
		lines.append(current_line)

	var line_height := float(font.get_height(font_size)) if font != null else float(font_size)
	var y_offset := 0.0
	for line in lines:
		var line_width := font.get_string_size(line, 0, -1, font_size).x
		draw_string(font, center_pos + Vector2(-line_width * 0.5, y_offset), line, 0, -1, font_size, color)
		y_offset += line_height
