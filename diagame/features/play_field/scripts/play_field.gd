extends Node2D

const CARD_SIZE := Vector2(176, 176)
const FRAME_SIZE := Vector2(197, 176)
const ROSTER_X := 15.0
const ROSTER_Y: Array[int] = [0, 68, 260, 452, 644, 836]
const ENEMY_X: Array[int] = [0, 913, 1238, 1563]
const ENEMY_Y := 143.0
const ENGAGE_Y := 452.0
const TITLE_POS := Vector2(1110, 44)
const VS_POS := Vector2(1292, 396)
const LEVEL_OFFSET := Vector2(164, 22)
const CHANCE_POS := Vector2(1238, 761)
const START_BUTTON_POS := Vector2(1563, 761)
const REWARD_PANEL_POS := Vector2(913, 761)
const START_BUTTON_SIZE := CARD_SIZE
const DESIGN_SIZE := Vector2(1920, 1080)

@export var use_gm_dynamic_guidance: bool = true

var frame_texture: Texture2D
var flare_texture: Texture2D
var empty_box_texture: Texture2D
var next_button_texture: Texture2D
var marker_sprite: Sprite2D
var marker2_sprite: Sprite2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}
var arcade_font: Font
var card_sfx_player: AudioStreamPlayer

var mission_data: Dictionary = {}
var mission_enemies: Array[int] = []

var engage_slots: Array[int] = [0, 0, 0, 0] # 1..3 used
var hovered_roster_slot: int = 0
var hovered_engage_slot: int = 0
var hovered_start_button: bool = false
var current_win_chance: float = 0.0
var battle_complete: bool = false
var battle_won: bool = false
var show_results: bool = false
var result_timer: float = 0.0
var result_text: String = ""

var particle_overlay_scene = preload("res://core/fx/starfield/particle_overlay.tscn")

func _ready():
	randomize()
	GameState.ensure_ported_data()
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	flare_texture = load("res://assets/sprites/Flare.png")
	empty_box_texture = load("res://assets/sprites/Empty_0.png")
	next_button_texture = load("res://assets/sprites/Next_0.png")

	var mission_idx := GameState.intMissionSelected
	var raw_mission: Variant = GameState.arrayMissions[mission_idx]
	if raw_mission == null:
		push_error("play_field: mission %d missing" % mission_idx)
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")
		return
	mission_data = raw_mission

	_extract_mission_enemies()
	_load_textures()
	_setup_audio()
	_setup_ambient_fx()
	_reset_engage_state()
	_update_layout_to_viewport()

	queue_redraw()

func _setup_audio():
	card_sfx_player = AudioStreamPlayer.new()
	card_sfx_player.stream = load("res://assets/sounds/sound1.wav")
	card_sfx_player.volume_db = -2.0
	add_child(card_sfx_player)

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
		var raw_hero: Variant = GameState.arrayHeroes[i]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if hero.has("texture_path"):
			hero_textures[i] = load(str(hero["texture_path"]))

	for i in range(1, 8):
		var raw_enemy: Variant = GameState.arrayEnemies[i]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if enemy.has("texture_path"):
			enemy_textures[i] = load(str(enemy["texture_path"]))

func _setup_ambient_fx():
	marker_sprite = Sprite2D.new()
	marker_sprite.position = Vector2(1001, 540)
	marker_sprite.texture = flare_texture
	marker_sprite.script = load("res://core/fx/markers/marker.gd")
	marker_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker_sprite.z_index = -10
	add_child(marker_sprite)

	marker2_sprite = Sprite2D.new()
	marker2_sprite.position = Vector2(1001, 540)
	marker2_sprite.texture = flare_texture
	marker2_sprite.script = load("res://core/fx/markers/marker2.gd")
	marker2_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	marker2_sprite.z_index = -10
	add_child(marker2_sprite)

	var stripe: Sprite2D = particle_overlay_scene.instantiate()
	stripe.scale = Vector2(40, 11)
	var y_offset := 0.0
	if stripe.texture != null:
		y_offset = stripe.texture.get_height() * stripe.scale.y * 0.5
	stripe.position = Vector2(-1900, 540 - y_offset)
	stripe.z_index = -10
	stripe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(stripe)

func _reset_engage_state():
	for i in range(1, 4):
		engage_slots[i] = 0
		GameState.arrayEngageSlots[i] = null
	_recalculate_win_chance()
	_update_marker_target()

func _process(delta: float):
	_update_layout_to_viewport()
	_update_hover_state()
	_update_starfield_speed_from_chance()
	if show_results:
		result_timer += delta
		if result_timer >= 3.0:
			_return_to_mission_select()
	queue_redraw()

func _update_hover_state():
	hovered_roster_slot = 0
	hovered_engage_slot = 0
	hovered_start_button = false

	if battle_complete:
		return

	var local_mouse := to_local(get_viewport().get_mouse_position())

	for hero_id in range(1, 6):
		var roster_rect := Rect2(Vector2(ROSTER_X, ROSTER_Y[hero_id]), CARD_SIZE)
		if roster_rect.has_point(local_mouse):
			hovered_roster_slot = hero_id
			return

	for s in range(1, 4):
		var engage_rect := Rect2(Vector2(ENEMY_X[s], ENGAGE_Y), CARD_SIZE)
		if engage_rect.has_point(local_mouse):
			hovered_engage_slot = s
			return

	hovered_start_button = _get_start_button_rect().has_point(local_mouse) and current_win_chance > 0.0

func _input(event: InputEvent):
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var mouse_event: InputEventMouseButton = event

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_return_to_mission_select()
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
				GameState.arrayEngageSlots[s] = null
				_recalculate_win_chance()
				_play_card_sfx()
				return true

		# Otherwise put in first empty slot.
		for s in range(1, 4):
			if engage_slots[s] == 0:
				engage_slots[s] = hero_id
				GameState.arrayEngageSlots[s] = hero_id
				_recalculate_win_chance()
				_play_card_sfx()
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
			GameState.arrayEngageSlots[s] = null
			_recalculate_win_chance()
			_play_card_sfx()
		return true
	return false

func _play_card_sfx():
	if card_sfx_player != null and card_sfx_player.stream != null:
		card_sfx_player.play()

func _recalculate_win_chance():
	current_win_chance = 0.0
	var mission_level := int(mission_data.get("intLevel", 1))

	for s in range(1, 4):
		var hero_id := engage_slots[s]
		if hero_id == 0:
			continue
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero

		var hero_level := int(hero.get("intLevel", 1))
		var hero_ability := int(hero.get("skillSlot1", 1))
		var chance := 50.0 / 3.0
		var counter_bonus := 0.0

		for enemy_id in mission_enemies:
			var raw_enemy: Variant = GameState.arrayEnemies[enemy_id]
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
	GameState.intBattleWinChance = current_win_chance
	_update_marker_target()

func _update_marker_target():
	if marker_sprite == null or marker2_sprite == null:
		return

	if not use_gm_dynamic_guidance:
		var default_target := Vector2(1001, 540)
		marker_sprite.position = default_target
		marker2_sprite.position = default_target
		return

	# GameMaker moveMarker.gml behavior:
	# slot1 empty -> x=1001,y=540
	# slot2 empty -> x=1326,y=540
	# slot3 empty -> x=1651,y=540
	# all full and winChance>0 -> x=1651,y=849 (fight button)
	# all full and winChance==0 -> x=1825,y=0
	var target := Vector2(1001, 540)
	if engage_slots[1] == 0:
		target = Vector2(1001, 540)
	elif engage_slots[2] == 0:
		target = Vector2(1326, 540)
	elif engage_slots[3] == 0:
		target = Vector2(1651, 540)
	elif current_win_chance > 0.0:
		target = Vector2(1651, 849)
	else:
		target = Vector2(1825, 0)

	marker_sprite.position = target
	marker2_sprite.position = target

func _update_starfield_speed_from_chance():
	if not use_gm_dynamic_guidance:
		return

	# GameMaker missionCancelButton Step behavior in playField:
	# target = 24 * chanceBar.chance / 200
	# if starSpeed < target: starSpeed *= 1.03; starSize *= 1.03
	# elif starSpeed > target and starSpeed > 2: starSpeed *= 0.97; starSize *= 0.97
	var target_speed: float = 24.0 * current_win_chance / 200.0
	if GameState.star_speed < target_speed:
		GameState.star_speed *= 1.03
		GameState.star_size *= 1.03
	elif GameState.star_speed > target_speed and GameState.star_speed > 2.0:
		GameState.star_speed *= 0.97
		GameState.star_size *= 0.97

func _execute_battle():
	battle_complete = true
	GameState.intBattleWinChance = current_win_chance
	for i in range(1, 4):
		GameState.arrayFightingHeroes[i] = null
		if engage_slots[i] > 0:
			GameState.arrayFightingHeroes[i] = engage_slots[i]

	#if ResourceLoader.exists("res://features/fight_room/scenes/fight_room_3d.tscn"):
	#	get_tree().change_scene_to_file("res://features/fight_room/scenes/fight_room_3d.tscn")
	#if ResourceLoader.exists("res://features/fight_room/scenes/fight_room_skeleton2D.tscn"):
	#	get_tree().change_scene_to_file("res://features/fight_room/scenes/fight_room_skeleton2D.tscn")
	if ResourceLoader.exists("res://features/fight_room/scenes/fight_room_skeleton2D_direct.tscn"):
		get_tree().change_scene_to_file("res://features/fight_room/scenes/fight_room_skeleton2D_direct.tscn")
	#if ResourceLoader.exists("res://features/fight_room/scenes/fight_room_perspective.tscn"):
	#	get_tree().change_scene_to_file("res://features/fight_room/scenes/fight_room_perspective.tscn")
	#if ResourceLoader.exists("res://features/fight_room/scenes/fight_room.tscn"):
	#	get_tree().change_scene_to_file("res://features/fight_room/scenes/fight_room.tscn")
	else:
		print("fight_room is not ported yet.")
		battle_complete = false

func _return_to_mission_select():
	GameState.reset_starfield_defaults()
	get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

func _apply_level_up():
	var xp_reward := int(mission_data.get("intXp", 100))
	for s in range(1, 4):
		var hero_id := engage_slots[s]
		if hero_id == 0:
			continue
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero

		var new_xp := int(hero.get("intXp", 0)) + xp_reward
		hero["intXp"] = new_xp

		var level := int(hero.get("intLevel", 1))
		if level + 1 < GameState.arrayLevels.size():
			var next_level_xp := int(GameState.arrayLevels[level + 1])
			if new_xp >= next_level_xp:
				hero["intLevel"] = level + 1

func _draw():
	_draw_title()
	_draw_vs()
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
	draw_string(arcade_font, blue_pos, "PREPARE FOR BATTLE", HORIZONTAL_ALIGNMENT_LEFT, 440, 24, Color(0.0, 0.0, 1.0))
	draw_string(arcade_font, white_pos, "PREPARE FOR BATTLE", HORIZONTAL_ALIGNMENT_LEFT, 440, 24, Color.WHITE)

func _draw_vs():
	if arcade_font == null:
		return
	var base_pos := _with_text_height(VS_POS, 24)
	draw_string(arcade_font, base_pos + Vector2(3, 3), "VS.", HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color(0.0, 0.0, 1.0))
	draw_string(arcade_font, base_pos, "VS.", HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color.WHITE)

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
		draw_string(arcade_font, _with_text_height(rect.position + LEVEL_OFFSET, 24), level_text, HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color.BLACK)

		var raw_enemy: Variant = GameState.arrayEnemies[enemy_id]
		if raw_enemy != null:
			var enemy_data: Dictionary = raw_enemy
			var enemy_name := _break_after_first_word(str(enemy_data.get("name", "Enemy")))
			var ability_index := int(enemy_data.get("ability", 1))
			var ability_name := "Ability"
			if ability_index > 0 and ability_index < GameState.arrayAbilities.size() and GameState.arrayAbilities[ability_index] != null:
				ability_name = str(GameState.arrayAbilities[ability_index])
			ability_name = _break_after_first_word(ability_name)
			_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(88, -48), 24), enemy_name, 24, 276, Color.WHITE)
			_draw_centered_wrapped_text(arcade_font, _with_text_height(rect.position + Vector2(88, 179), 24), ability_name, 24, 276, Color.WHITE)

func _draw_roster():
	if arcade_font == null:
		return
	for hero_id in range(1, 6):
		var rect := Rect2(Vector2(ROSTER_X, ROSTER_Y[hero_id]), CARD_SIZE)
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
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
		if hovered_roster_slot == hero_id:
			draw_rect(rect.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)
		if frame_texture != null:
			var frame_rect := Rect2(rect.position, FRAME_SIZE)
			draw_texture_rect(frame_texture, frame_rect, false)

		var level := int(hero.get("intLevel", 1))
		var xp := int(hero.get("intXp", 0))
		var class_label := str(hero.get("class", "Hero"))
		var ability_idx := int(hero.get("skillSlot1", 1))
		var ability_name := "Ability"
		if ability_idx > 0 and ability_idx < GameState.arrayAbilities.size() and GameState.arrayAbilities[ability_idx] != null:
			ability_name = str(GameState.arrayAbilities[ability_idx])
		var current_level_floor: int = int(GameState.arrayLevels[level]) if level < GameState.arrayLevels.size() else 0
		var next_level: int = int(GameState.arrayLevels[level + 1]) if level + 1 < GameState.arrayLevels.size() else xp + 1
		var current_level_xp: int = max(0, xp - current_level_floor)
		var level_delta: int = max(1, next_level - current_level_floor)

		draw_string(arcade_font, _with_text_height(rect.position + LEVEL_OFFSET, 24), "%d" % level, HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color.BLACK)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 22), 24), class_label, HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 48), 24), "XP:%d/%d" % [current_level_xp, level_delta], HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)
		draw_string(arcade_font, _with_text_height(rect.position + Vector2(204, 72), 24), ability_name, HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)

func _draw_engage_slots():
	if arcade_font == null:
		return
	for s in range(1, 4):
		var rect := Rect2(Vector2(ENEMY_X[s], ENGAGE_Y), CARD_SIZE)
		if hovered_engage_slot == s and engage_slots[s] != 0:
			draw_rect(rect.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)
		if empty_box_texture != null:
			draw_texture_rect(empty_box_texture, rect, false)
		else:
			draw_rect(rect, Color(0.05, 0.05, 0.05, 0.75), true)
		var hero_id := engage_slots[s]
		if hero_id != 0:
			var tex: Texture2D = hero_textures.get(hero_id, null)
			if tex != null:
				draw_texture_rect(tex, rect, false)

func _draw_bottom_ui():
	if arcade_font == null:
		return

	# Reward panel (legacy rewardFrame replacement)
	var reward_rect := Rect2(REWARD_PANEL_POS, CARD_SIZE)
	var reward_text := "Reward: %d XP" % int(mission_data.get("intXp", 0))
	reward_text = _break_after_first_word(reward_text)
	_draw_wrapped_text(arcade_font, _with_text_height(reward_rect.position + Vector2(13, 13), 24), reward_text, 24, 176, Color.BLUE)
	_draw_wrapped_text(arcade_font, _with_text_height(reward_rect.position + Vector2(10, 10), 24), reward_text, 24, 176, Color.WHITE)

	# Chance bar at x=1238,y=761
	var chance_rect := Rect2(CHANCE_POS, CARD_SIZE)
	var fill_width := (CARD_SIZE.x - 20.0) * (current_win_chance / 100.0)
	draw_rect(Rect2(chance_rect.position + Vector2(10, 82), Vector2(fill_width, 12)), Color(0.2, 0.9, 0.35, 0.95), true)
	var print_chance := int(min(100.0, current_win_chance))
	var win_text := "Chance to win:\n%d%%" % print_chance
	win_text = _break_after_first_word(win_text)
	_draw_wrapped_text(arcade_font, _with_text_height(chance_rect.position + Vector2(13, 13), 24), win_text, 24, 176, Color.BLUE)
	_draw_wrapped_text(arcade_font, _with_text_height(chance_rect.position + Vector2(10, 10), 24), win_text, 24, 176, Color.WHITE)

	# Start button at x=1563,y=761 (missionStartButton replacement)
	var button_rect := _get_start_button_rect()
	var enabled := current_win_chance > 0.0 and not battle_complete
	if hovered_start_button:
		draw_rect(button_rect.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)
	if next_button_texture != null:
		draw_texture_rect(next_button_texture, button_rect, false, Color(1, 1, 1, 1.0 if enabled else 0.65))
	else:
		draw_rect(button_rect, Color.WHITE, false, 2.0)
	draw_string(arcade_font, _with_text_height(button_rect.position + Vector2(36, 52), 24), "FIGHT", HORIZONTAL_ALIGNMENT_LEFT, 120, 24, Color.WHITE)

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
		var text_size := font.get_string_size(test_text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size)
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
			draw_string(font, pos + Vector2(0, y_offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
		draw_string(font, pos + Vector2(0, y_offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
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
		var text_size := font.get_string_size(test_text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size)
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
		var line_width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, center_pos + Vector2(-line_width * 0.5, y_offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		y_offset += line_height
