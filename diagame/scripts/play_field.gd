extends Node2D

const CARD_SIZE := Vector2(176, 176)
const FRAME_SIZE := Vector2(197, 176)
const ROSTER_X := 15.0
const ROSTER_Y: Array[int] = [0, 68, 260, 452, 644, 836]
const ENEMY_X: Array[int] = [0, 913, 1238, 1563]
const ENEMY_Y := 143.0
const ENGAGE_Y := 452.0
const TITLE_POS := Vector2(1110, 44)
const LEVEL_OFFSET := Vector2(164, 22)
const CHANCE_POS := Vector2(1238, 761)
const START_BUTTON_POS := Vector2(1563, 761)
const REWARD_PANEL_POS := Vector2(913, 761)
const START_BUTTON_SIZE := Vector2(176, 88)
const DESIGN_SIZE := Vector2(1920, 1080)

var frame_texture: Texture2D
var flare_texture: Texture2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}
var arcade_font: Font

var mission_data: Dictionary = {}
var mission_enemies: Array[int] = []

var engage_slots: Array[int] = [0, 0, 0, 0] # 1..3 used
var current_win_chance: float = 0.0
var battle_complete: bool = false
var battle_won: bool = false
var show_results: bool = false
var result_timer: float = 0.0
var result_text: String = ""

var particle_overlay_scene = preload("res://scenes/particle_overlay.tscn")

func _ready():
	randomize()
	Global.ensure_ported_data()
	arcade_font = Global.arcade_font if Global.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	flare_texture = load("res://assets/sprites/Flare.png")

	var mission_idx := Global.intMissionSelected
	var raw_mission: Variant = Global.arrayMissions[mission_idx]
	if raw_mission == null:
		push_error("play_field: mission %d missing" % mission_idx)
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
		return
	mission_data = raw_mission

	_extract_mission_enemies()
	_load_textures()
	_setup_ambient_fx()
	_reset_engage_state()
	_update_layout_to_viewport()

	queue_redraw()

func _update_layout_to_viewport():
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = min(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	scale = Vector2(fit_scale, fit_scale)
	position = (viewport_size - (DESIGN_SIZE * fit_scale)) * 0.5

func _extract_mission_enemies():
	mission_enemies.clear()
	var raw_enemies: Variant = mission_data.get("arrayEnemies", null)
	if raw_enemies == null:
		mission_enemies = [1, 2, 3]
		return

	for v in raw_enemies:
		if v == null:
			continue
		var eid := int(v)
		if eid <= 0:
			continue
		mission_enemies.append(eid)
		if mission_enemies.size() == 3:
			break

	while mission_enemies.size() < 3:
		mission_enemies.append(1)

func _load_textures():
	for i in range(1, 6):
		var raw_hero: Variant = Global.arrayHeroes[i]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if hero.has("texture_path"):
			hero_textures[i] = load(str(hero["texture_path"]))

	for i in range(1, 8):
		var raw_enemy: Variant = Global.arrayEnemies[i]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if enemy.has("texture_path"):
			enemy_textures[i] = load(str(enemy["texture_path"]))

func _setup_ambient_fx():
	var marker := Sprite2D.new()
	marker.position = Vector2(1001, 540)
	marker.texture = flare_texture
	marker.script = load("res://scripts/marker.gd")
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker.z_index = 20
	add_child(marker)

	var marker2 := Sprite2D.new()
	marker2.position = Vector2(1001, 540)
	marker2.texture = flare_texture
	marker2.script = load("res://scripts/marker2.gd")
	marker2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker2.z_index = 20
	add_child(marker2)

	var stripe: Sprite2D = particle_overlay_scene.instantiate()
	stripe.scale = Vector2(40, 11)
	var y_offset := 0.0
	if stripe.texture != null:
		y_offset = stripe.texture.get_height() * stripe.scale.y * 0.5
	stripe.position = Vector2(-1900, 540 - y_offset)
	stripe.z_index = 5
	stripe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(stripe)

func _reset_engage_state():
	for i in range(1, 4):
		engage_slots[i] = 0
		Global.arrayEngageSlots[i] = null
	_recalculate_win_chance()

func _process(delta: float):
	_update_layout_to_viewport()
	if show_results:
		result_timer += delta
		if result_timer >= 3.0:
			get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
	queue_redraw()

func _input(event: InputEvent):
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var mouse_event: InputEventMouseButton = event

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT or battle_complete:
		return

	var p: Vector2 = to_local(mouse_event.position)

	if _handle_roster_click(p):
		return
	if _handle_engage_click(p):
		return
	if _get_start_button_rect().has_point(p) and current_win_chance > 0.0:
		_execute_battle()

func _handle_roster_click(p: Vector2) -> bool:
	for hero_id in range(1, 6):
		var rect := Rect2(Vector2(ROSTER_X, ROSTER_Y[hero_id]), CARD_SIZE)
		if not rect.has_point(p):
			continue

		# Toggle off if already selected.
		for s in range(1, 4):
			if engage_slots[s] == hero_id:
				engage_slots[s] = 0
				Global.arrayEngageSlots[s] = null
				_recalculate_win_chance()
				return true

		# Otherwise put in first empty slot.
		for s in range(1, 4):
			if engage_slots[s] == 0:
				engage_slots[s] = hero_id
				Global.arrayEngageSlots[s] = hero_id
				_recalculate_win_chance()
				return true
		return true
	return false

func _handle_engage_click(p: Vector2) -> bool:
	for s in range(1, 4):
		var rect := Rect2(Vector2(ENEMY_X[s], ENGAGE_Y), CARD_SIZE)
		if not rect.has_point(p):
			continue
		if engage_slots[s] != 0:
			engage_slots[s] = 0
			Global.arrayEngageSlots[s] = null
			_recalculate_win_chance()
		return true
	return false

func _recalculate_win_chance():
	current_win_chance = 0.0
	var mission_level := int(mission_data.get("intLevel", 1))

	for s in range(1, 4):
		var hero_id := engage_slots[s]
		if hero_id == 0:
			continue
		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero

		var hero_level := int(hero.get("intLevel", 1))
		var hero_ability := int(hero.get("skillSlot1", 1))
		var chance := 50.0 / 3.0
		var counter_bonus := 0.0

		for enemy_id in mission_enemies:
			var raw_enemy: Variant = Global.arrayEnemies[enemy_id]
			if raw_enemy == null:
				continue
			var enemy: Dictionary = raw_enemy
			if hero_ability == int(enemy.get("ability", 0)):
				counter_bonus = 100.0 / 3.0
				break

		var modifier := 0.0
		if hero_level <= mission_level - 3:
			modifier = 0.0
		elif hero_level == mission_level - 2:
			modifier = 0.25
		elif hero_level == mission_level - 1:
			modifier = 0.5
		elif hero_level == mission_level:
			modifier = 1.0
		elif hero_level == mission_level + 1:
			modifier = 1.25
		else:
			modifier = 1.5

		current_win_chance += (chance + counter_bonus) * modifier

	current_win_chance = clampf(current_win_chance, 0.0, 100.0)
	Global.intBattleWinChance = current_win_chance

func _execute_battle():
	battle_complete = true
	Global.intBattleWinChance = current_win_chance
	for i in range(1, 4):
		Global.arrayFightingHeroes[i] = null
		if engage_slots[i] > 0:
			Global.arrayFightingHeroes[i] = engage_slots[i]

	if ResourceLoader.exists("res://scenes/fight_room.tscn"):
		get_tree().change_scene_to_file("res://scenes/fight_room.tscn")
	else:
		print("fight_room is not ported yet.")
		battle_complete = false

func _apply_level_up():
	var xp_reward := int(mission_data.get("intXp", 100))
	for s in range(1, 4):
		var hero_id := engage_slots[s]
		if hero_id == 0:
			continue
		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero

		var new_xp := int(hero.get("intXp", 0)) + xp_reward
		hero["intXp"] = new_xp

		var level := int(hero.get("intLevel", 1))
		if level + 1 < Global.arrayLevels.size():
			var next_level_xp := int(Global.arrayLevels[level + 1])
			if new_xp >= next_level_xp:
				hero["intLevel"] = level + 1

func _draw():
	_draw_title()
	_draw_enemies()
	_draw_roster()
	_draw_engage_slots()
	_draw_bottom_ui()
	if show_results:
		_draw_results_overlay()

func _draw_title():
	if arcade_font == null:
		return
	var blue_pos := _with_text_height(TITLE_POS + Vector2(3, 3), 24)
	var white_pos := _with_text_height(TITLE_POS, 24)
	draw_string(arcade_font, blue_pos, "PREPARE FOR BATTLE", 0, 440, 24, Color(0.0, 0.0, 1.0))
	draw_string(arcade_font, white_pos, "PREPARE FOR BATTLE", 0, 440, 24, Color.WHITE)

func _draw_enemies():
	if arcade_font == null:
		return
	for i in range(1, 4):
		var enemy_id := mission_enemies[i - 1]
		var rect := Rect2(Vector2(ENEMY_X[i], ENEMY_Y), CARD_SIZE)
		var tex: Texture2D = enemy_textures.get(enemy_id, null)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		else:
			draw_rect(rect, Color(0.2, 0.2, 0.2, 0.85), true)
		if frame_texture != null:
			var frame_rect := Rect2(rect.position, FRAME_SIZE)
			draw_texture_rect(frame_texture, frame_rect, false)
		var level_text := "%d" % int(mission_data.get("intLevel", 1))
		draw_string(arcade_font, _with_text_height(rect.position + LEVEL_OFFSET, 24), level_text, 0, 176, 24, Color.BLACK)

func _draw_roster():
	if arcade_font == null:
		return
	for hero_id in range(1, 6):
		var rect := Rect2(Vector2(ROSTER_X, ROSTER_Y[hero_id]), CARD_SIZE)
		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var tex: Texture2D = hero_textures.get(hero_id, null)

		var alpha := 1.0
		for s in range(1, 4):
			if engage_slots[s] == hero_id:
				alpha = 0.35
				break

		if tex != null:
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
		else:
			draw_rect(rect, Color(0.2, 0.2, 0.2, 0.85), true)
		if frame_texture != null:
			var frame_rect := Rect2(rect.position, FRAME_SIZE)
			draw_texture_rect(frame_texture, frame_rect, false)

		var level := int(hero.get("intLevel", 1))
		var xp := int(hero.get("intXp", 0))
		var class_label := str(hero.get("class", "Hero"))
		var ability_idx := int(hero.get("skillSlot1", 1))
		var ability_name := "Ability"
		if ability_idx > 0 and ability_idx < Global.arrayAbilities.size() and Global.arrayAbilities[ability_idx] != null:
			ability_name = str(Global.arrayAbilities[ability_idx])
		var info := "%s XP:%d %s" % [class_label, xp, ability_name]
		info = _break_after_first_word(info)
		draw_string(arcade_font, _with_text_height(rect.position + LEVEL_OFFSET, 24), "%d" % level, 0, 176, 24, Color.BLACK)
		_draw_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(204, 22), 24), info, 24, 300, Color.WHITE)

func _draw_engage_slots():
	if arcade_font == null:
		return
	for s in range(1, 4):
		var rect := Rect2(Vector2(ENEMY_X[s], ENGAGE_Y), CARD_SIZE)
		draw_rect(rect, Color(0.05, 0.05, 0.05, 0.75), true)
		var hero_id := engage_slots[s]
		if hero_id != 0:
			var tex: Texture2D = hero_textures.get(hero_id, null)
			if tex != null:
				draw_texture_rect(tex, rect, false)
		if frame_texture != null:
			var frame_rect := Rect2(rect.position, FRAME_SIZE)
			draw_texture_rect(frame_texture, frame_rect, false)
		if hero_id == 0:
			draw_string(arcade_font, _with_text_height(rect.position + Vector2(28, 96), 24), "EMPTY", 0, 120, 24, Color(0.75, 0.75, 0.75))

func _draw_bottom_ui():
	if arcade_font == null:
		return

	# Reward panel (legacy rewardFrame replacement)
	var reward_rect := Rect2(REWARD_PANEL_POS, CARD_SIZE)
	draw_rect(reward_rect, Color(0.08, 0.08, 0.08, 0.85), true)
	if frame_texture != null:
		var reward_frame_rect := Rect2(reward_rect.position, FRAME_SIZE)
		draw_texture_rect(frame_texture, reward_frame_rect, false)
	var reward_text := "Reward %d XP" % int(mission_data.get("intXp", 0))
	reward_text = _break_after_first_word(reward_text)
	_draw_wrapped_text(arcade_font, _with_text_height(reward_rect.position + Vector2(12, 96), 24), reward_text, 24, 160, Color.WHITE)

	# Chance bar at x=1238,y=761
	var chance_rect := Rect2(CHANCE_POS, CARD_SIZE)
	draw_rect(chance_rect, Color(0.08, 0.08, 0.08, 0.85), true)
	if frame_texture != null:
		var chance_frame_rect := Rect2(chance_rect.position, FRAME_SIZE)
		draw_texture_rect(frame_texture, chance_frame_rect, false)
	var fill_width := (CARD_SIZE.x - 20.0) * (current_win_chance / 100.0)
	draw_rect(Rect2(chance_rect.position + Vector2(10, 82), Vector2(fill_width, 12)), Color(0.2, 0.9, 0.35, 0.95), true)
	var win_text := _break_after_first_word("Win %d%%" % int(current_win_chance))
	_draw_wrapped_text(arcade_font, _with_text_height(chance_rect.position + Vector2(12, 112), 24), win_text, 24, 150, Color.WHITE)

	# Start button at x=1563,y=761 (missionStartButton replacement)
	var button_rect := _get_start_button_rect()
	var enabled := current_win_chance > 0.0 and not battle_complete
	var bg := Color(0.12, 0.6, 0.2, 0.95) if enabled else Color(0.2, 0.2, 0.2, 0.8)
	draw_rect(button_rect, bg, true)
	if frame_texture != null:
		var button_frame_rect := Rect2(button_rect.position, FRAME_SIZE)
		draw_texture_rect(frame_texture, button_frame_rect, false)
	else:
		draw_rect(button_rect, Color.WHITE, false, 2.0)
	draw_string(arcade_font, _with_text_height(button_rect.position + Vector2(36, 52), 24), "FIGHT", 0, 120, 24, Color.WHITE)

func _draw_results_overlay():
	if arcade_font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color(0, 0, 0, 0.72), true)
	var color := Color(0.2, 1.0, 0.2) if battle_won else Color(1.0, 0.25, 0.25)
	var result_wrapped := _break_after_first_word(result_text)
	_draw_wrapped_text(arcade_font, _with_text_height(Vector2(860, 480), 42), result_wrapped, 42, 320, color)
	if battle_won:
		var earned_text := _break_after_first_word("%d XP EARNED" % int(mission_data.get("intXp", 0)))
		_draw_wrapped_text(arcade_font, _with_text_height(Vector2(740, 530), 22), earned_text, 22, 520, Color.WHITE)
	var return_text := _break_after_first_word("Returning to mission select...")
	_draw_wrapped_text(arcade_font, _with_text_height(Vector2(620, 610), 16), return_text, 16, 700, Color(0.85, 0.85, 0.85))

func _get_start_button_rect() -> Rect2:
	return Rect2(START_BUTTON_POS, START_BUTTON_SIZE)

func _with_text_height(pos: Vector2, font_size: int) -> Vector2:
	return pos + Vector2(0, float(font_size))

func _break_after_first_word(text: String) -> String:
	var split_index := text.find(" ")
	if split_index == -1:
		return text
	return text.substr(0, split_index) + "\n" + text.substr(split_index + 1)

func _draw_wrapped_text(font: Font, pos: Vector2, text: String, font_size: int, max_width: int, color: Color, outline_color: Color = Color.TRANSPARENT):
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
		if outline_color.a > 0.0:
			draw_string(font, pos + Vector2(0, y_offset), line, 0, -1, font_size, outline_color)
		draw_string(font, pos + Vector2(0, y_offset), line, 0, -1, font_size, color)
		y_offset += line_height
