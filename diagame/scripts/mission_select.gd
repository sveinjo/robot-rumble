extends Node2D

const SLOT_X: Array[int] = [0, 913, 1238, 1563]
const SLOT_Y: Array[int] = [0, 143, 452, 761]
const HERO_Y: Array[int] = [0, 68, 260, 452, 644, 836]
const CARD_SIZE := Vector2(176, 176)
const FRAME_SIZE := Vector2(197, 176)  # Frame sprite is wider than card
const LEVEL_OFFSET := Vector2(164, 22)

var frame_texture: Texture2D
var empty_texture: Texture2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}
var arcade_font: Font

var hovered_slot: int = 0
var particle_overlay_scene = preload("res://scenes/particle_overlay.tscn")

func _ready():
	randomize()
	Global.ensure_ported_data()
	arcade_font = Global.arcade_font if Global.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	empty_texture = load("res://assets/sprites/Empty_0.png")

	_load_textures()
	_setup_ambient_fx()
	_generate_missions_if_needed()
	queue_redraw()

func _load_textures():
	for i in range(1, 6):
		var hero_data: Dictionary = Global.arrayHeroes[i]
		if hero_data and hero_data.has("texture_path"):
			hero_textures[i] = load(hero_data["texture_path"])

	for i in range(1, 8):
		var enemy_data: Dictionary = Global.arrayEnemies[i]
		if enemy_data and enemy_data.has("texture_path"):
			enemy_textures[i] = load(enemy_data["texture_path"])

func _setup_ambient_fx():
	var marker_tex: Texture2D = load("res://assets/sprites/Flare.png")

	var marker := Sprite2D.new()
	marker.position = Vector2(1326, 540)
	marker.texture = marker_tex
	marker.script = load("res://scripts/marker.gd")
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker.z_index = -10
	add_child(marker)

	var marker2 := Sprite2D.new()
	marker2.position = Vector2(1326, 540)
	marker2.texture = marker_tex
	marker2.script = load("res://scripts/marker2.gd")
	marker2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker2.z_index = -10
	add_child(marker2)

	# Add flares for each row at Y positions matching the mission grid rows
	"""for y_pos in [231.0, 540.0, 849.0]:
		var marker := Sprite2D.new()
		marker.position = Vector2(1326, y_pos)
		marker.texture = marker_tex
		marker.script = load("res://scripts/marker.gd")
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker.z_index = 20
		add_child(marker) 

		var marker2 := Sprite2D.new()
		marker2.position = Vector2(1326, y_pos)
		marker2.texture = marker_tex
		marker2.script = load("res://scripts/marker2.gd")
		marker2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker2.z_index = 20
		add_child(marker2)"""

	for y_pos in [231.0, 540.0, 849.0]:
		var stripe: Sprite2D = particle_overlay_scene.instantiate()
		stripe.scale = Vector2(40, 11)
		var y_offset := 0.0
		if stripe.texture != null:
			y_offset = stripe.texture.get_height() * stripe.scale.y * 0.5
		stripe.position = Vector2(-1900, y_pos - y_offset)
		stripe.z_index = -10
		stripe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(stripe)

	# Deploy shared side menu for mission select
	# if Global.common_menu != null:
	#	Global.common_menu.panel_open = true

func _generate_missions_if_needed():
	for i in range(1, 10):
		if Global.arrayMissions[i] == null:
			_create_mission(i)
		else:
			var mission: Dictionary = Global.arrayMissions[i]
			if mission.get("isNew", false) and not mission.has("fade_flag"):
				mission["fade_flag"] = true
				mission["image_alpha"] = 0.0
				Global.arrayMissions[i] = mission

func _create_mission(index: int):
	var min_level := 999
	var max_level := -999

	for i in range(1, 6):
		var hero_data: Dictionary = Global.arrayHeroes[i]
		if hero_data == null:
			continue
		var level := int(hero_data.get("intLevel", 1))
		min_level = min(min_level, level)
		max_level = max(max_level, level)

	if min_level == 999:
		min_level = 1
		max_level = 1

	var mission_level := 1
	if index == 5:
		mission_level = max_level + 3 if Global.base_overtaken else max_level
	else:
		mission_level = randi_range(min_level, max_level)

	var bonus := 20 if mission_level == min_level else 0
	var should_spawn := (randi_range(0, 100) > (80 - bonus)) or index == 5
	if not should_spawn:
		Global.arrayMissions[index] = null
		return

	var boss_number := randi_range(3, 7)
	var henchmen_number := randi_range(1, 2)
	var xp_reward := mission_level * 300

	Global.arrayMissions[index] = {
		"enemy_id": boss_number,
		"arrayEnemies": [null, henchmen_number, boss_number, henchmen_number],
		"intLevel": mission_level,
		"intXp": xp_reward,
		"intBonusXp": xp_reward,
		"isNew": true,
		"fade_flag": true,
		"image_alpha": 0.0
	}

func _process(delta: float):
	_update_hover_state()
	_update_mission_fades(delta)
	queue_redraw()

func _update_hover_state():
	hovered_slot = 0
	var mouse_pos := get_viewport().get_mouse_position()
	for idx in range(1, 10):
		if _get_slot_rect(idx).has_point(mouse_pos):
			hovered_slot = idx
			return

func _update_mission_fades(delta: float):
	for i in range(1, 10):
		var raw_mission: Variant = Global.arrayMissions[i]
		if raw_mission == null:
			continue
		var mission: Dictionary = raw_mission
		if mission.get("fade_flag", false):
			var alpha := float(mission.get("image_alpha", 0.0))
			alpha = clamp(alpha + (0.025 * delta * 60.0), 0.0, 1.0)
			mission["image_alpha"] = alpha
			if alpha >= 1.0:
				mission["fade_flag"] = false
				mission["isNew"] = false
			Global.arrayMissions[i] = mission

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_left_click(event.position)

func _handle_left_click(mouse_pos: Vector2):
	for idx in range(1, 10):
		if not _get_slot_rect(idx).has_point(mouse_pos):
			continue

		if idx == 5 and not Global.base_overtaken:
			if ResourceLoader.exists("res://scenes/home_base.tscn"):
				get_tree().change_scene_to_file("res://scenes/home_base.tscn")
			else:
				print("Home Base is not ported yet.")
			return

		var raw_mission: Variant = Global.arrayMissions[idx]
		if raw_mission == null:
			return
		var mission: Dictionary = raw_mission

		Global.intMissionSelected = idx
		if ResourceLoader.exists("res://scenes/play_field.tscn"):
			get_tree().change_scene_to_file("res://scenes/play_field.tscn")
		else:
			print("Selected mission %d (play_field room not ported yet)." % idx)
		return

func _draw():
	_draw_titles()
	_draw_roster()
	_draw_mission_grid()

func _draw_titles():
	var font := arcade_font if arcade_font else ThemeDB.fallback_font
	var title_blue_pos := _with_text_height(Vector2(1163, 47), 24)
	var title_white_pos := _with_text_height(Vector2(1160, 44), 24)
	draw_string(font, title_blue_pos, "SELECT MISSION", 0, 440, 24, Color.BLUE)
	draw_string(font, title_white_pos, "SELECT MISSION", 0, 440, 24, Color.WHITE)

func _draw_roster():
	var font := arcade_font if arcade_font else ThemeDB.fallback_font
	for i in range(1, 6):
		var hero_rect := Rect2(Vector2(15, HERO_Y[i]), CARD_SIZE)
		var hero_frame_rect := Rect2(Vector2(15, HERO_Y[i]), FRAME_SIZE)
		var hero_tex: Texture2D = hero_textures.get(i, null)
		if hero_tex:
			draw_texture_rect(hero_tex, hero_rect, false, Color(1, 1, 1, 0.25))
		else:
			draw_rect(hero_rect, Color(0.2, 0.2, 0.2, 0.75), true)

		if frame_texture:
			draw_texture_rect(frame_texture, hero_frame_rect, false)

		var hero_data: Dictionary = Global.arrayHeroes[i]
		if hero_data == null:
			continue

		var ability_index := int(hero_data.get("skillSlot1", 1))
		var ability_name: String = str(Global.arrayAbilities[ability_index]) if ability_index < Global.arrayAbilities.size() else "Ability"
		var level := int(hero_data.get("intLevel", 1))
		var xp := int(hero_data.get("intXp", 0))
		var current_level_floor: int = int(Global.arrayLevels[level]) if level < Global.arrayLevels.size() else 0
		var next_level: int = int(Global.arrayLevels[level + 1]) if level + 1 < Global.arrayLevels.size() else xp + 1
		var current_level_xp: int = max(0, xp - current_level_floor)
		var level_delta: int = max(1, next_level - current_level_floor)

		var hero_class: String = str(hero_data.get("class", "Hero"))
		# Draw level inside the shield, then class / XP progress / ability on separate lines.
		draw_string(font, _with_text_height(hero_rect.position + LEVEL_OFFSET, 24), "%d" % level, 0, 176, 24, Color.BLACK)
		draw_string(font, _with_text_height(hero_rect.position + Vector2(204, 22), 24), hero_class, 0, 300, 24, Color.WHITE)
		draw_string(font, _with_text_height(hero_rect.position + Vector2(204, 48), 24), "XP:%d/%d" % [current_level_xp, level_delta], 0, 300, 24, Color.WHITE)
		draw_string(font, _with_text_height(hero_rect.position + Vector2(204, 72), 24), ability_name, 0, 300, 24, Color.WHITE)

func _draw_mission_grid():
	var font := arcade_font if arcade_font else ThemeDB.fallback_font

	for idx in range(1, 10):
		var slot_rect := _get_slot_rect(idx)
		var frame_rect := Rect2(slot_rect.position, FRAME_SIZE)
		var is_hovered := hovered_slot == idx

		if idx == 5 and not Global.base_overtaken:
			if empty_texture != null:
				draw_texture_rect(empty_texture, slot_rect, false)
			else:
				draw_rect(slot_rect, Color(0.08, 0.08, 0.08, 0.95), true)
			if is_hovered:
				draw_rect(slot_rect.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)
			var home_text := _break_after_first_word("HOME BASE")
			_draw_wrapped_text(font, _with_text_height(slot_rect.position + Vector2(16, 16), 24), home_text, 24, 176, Color.WHITE)
			continue

		var raw_mission: Variant = Global.arrayMissions[idx]
		if raw_mission == null:
			draw_rect(slot_rect, Color(0.05, 0.05, 0.05, 0.75), true)
			if frame_texture:
				draw_texture_rect(frame_texture, frame_rect, false)
			continue
		var mission: Dictionary = raw_mission

		var alpha := float(mission.get("image_alpha", 1.0))
		var enemy_id := int(mission.get("enemy_id", 1))
		var enemy_tex: Texture2D = enemy_textures.get(enemy_id, null)
		if is_hovered:
			draw_rect(slot_rect, Color(0.04, 0.04, 0.1, 0.95), true)
			var reward_text := "Reward: %d XP" % int(mission.get("intXp", 0))
			reward_text = _break_after_first_word(reward_text)
			_draw_wrapped_text(font, _with_text_height(slot_rect.position + Vector2(13, 13), 24), reward_text, 24, 176, Color.BLUE)
			_draw_wrapped_text(font, _with_text_height(slot_rect.position + Vector2(10, 10), 24), reward_text, 24, 176, Color.WHITE)
		else:
			if enemy_tex:
				draw_texture_rect(enemy_tex, slot_rect, false, Color(1, 1, 1, alpha))
			else:
				draw_rect(slot_rect, Color(0.2, 0.2, 0.2, alpha), true)

		if is_hovered:
			draw_rect(slot_rect.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)

		if frame_texture:
			draw_texture_rect(frame_texture, frame_rect, false)

		var level_text := "%d" % int(mission.get("intLevel", 1))
		# Draw level number inside the shield in black.
		draw_string(font, _with_text_height(slot_rect.position + LEVEL_OFFSET, 24), level_text, 0, 176, 24, Color.BLACK)

func _get_slot_rect(index: int) -> Rect2:
	var x_idx := ((index - 1) % 3) + 1
	var y_idx := int((index - 1) / 3) + 1
	return Rect2(Vector2(SLOT_X[x_idx], SLOT_Y[y_idx]), CARD_SIZE)

func _with_text_height(pos: Vector2, font_size: int) -> Vector2:
	return pos + Vector2(0, float(font_size))

func _break_after_first_word(text: String) -> String:
	var split_index := text.find(" ")
	if split_index == -1:
		return text
	return text.substr(0, split_index) + "\n" + text.substr(split_index + 1)

# Helper function to wrap text similar to GameMaker's draw_text_ext
func _draw_wrapped_text(font: Font, pos: Vector2, text: String, font_size: int, max_width: int, color: Color, outline_color: Color = Color.TRANSPARENT):
	# Split text into words and wrap based on max_width
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
	
	# Draw outlined text for each line
	var line_height := float(font.get_height(font_size)) if font != null else float(font_size)
	var y_offset := 0.0
	for line in lines:
		if outline_color.a > 0.0:
			draw_string(font, pos + Vector2(0, y_offset), line, 0, -1, font_size, outline_color)
		draw_string(font, pos + Vector2(0, y_offset), line, 0, -1, font_size, color)
		y_offset += line_height
