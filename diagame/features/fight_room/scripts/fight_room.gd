extends Node2D

const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_SIZE := Vector2(176, 176)
const LEFT_X: Array[int] = [0, 730, 506, 282]
const RIGHT_X: Array[int] = [0, 1014, 1238, 1462]
const COMBAT_CENTER_SHIFT := 88.0
const FIGHT_Y := 540.0
const REWARD_Y := 652.0
const RETURN_BUTTON_POS := Vector2(1563, 761)
const RETURN_BUTTON_SIZE := CARD_SIZE
const TITLE_Y := 44.0
const BANNER_Y := 96.0
const TEXT_CENTER_X := 960.0
const START_DELAY := 40.0 / 60.0
const IMPACT_DELAY := 20.0 / 60.0
const CHAIN_DELAY := 60.0 / 60.0
const GROUP_FADE_DELAY := 20.0 / 60.0
const VICTORY_POST_DELAY := 60.0 / 60.0

@export var show_star_debug_counts: bool = true

var arcade_font: Font
var flare_texture: Texture2D
var next_button_texture: Texture2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}

var selected_heroes: Array[int] = []
var mission_enemies: Array[int] = []
var mission_data: Dictionary = {}

var left_fighters: Array[Dictionary] = []
var right_fighters: Array[Dictionary] = []

var strike_index: int = 0
var enemies_left: int = 0
var win_flag: bool = false
var battle_started: bool = false
var battle_finished: bool = false
var return_visible: bool = false
var hovered_return_button: bool = false
var reward_visible: bool = false
var xp_reward: int = 0

var action_timer: float = 0.0
var hit_timer: float = 0.0
var post_victory_timer: float = 0.0
var pending_hit: bool = false
var pending_attack_from_left: bool = true
var pending_target_index: int = -1
var motion_step_accumulator: float = 0.0
var group_fade_timer: float = 0.0

func _ready():
	randomize()
	GameState.ensure_ported_data()
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	flare_texture = load("res://assets/sprites/Flare.png")
	next_button_texture = load("res://assets/sprites/Next_0.png")

	_load_mission_state()
	_build_fighter_lines()
	_setup_ambient_fx()
	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	GameState.set_starfield_spawn_interval(1.0 / 60.0)
	_update_layout_to_viewport()

	# Match GM flow: determine win/loss right after entering fight room.    
	var roll: int = randi_range(0, 100)
	win_flag = roll <= int(round(GameState.intBattleWinChance))
	GameState.winFlag = 1 if win_flag else 0

	if win_flag:
		_apply_level_up_rewards()

	strike_index = 0
	enemies_left = right_fighters.size()
	action_timer = START_DELAY
	hit_timer = 0.0
	post_victory_timer = 0.0
	pending_hit = false
	group_fade_timer = 0.0
	battle_started = true
	queue_redraw()

func _load_mission_state():
	selected_heroes.clear()
	for i in range(1, 4):
		var slot: Variant = GameState.arrayEngageSlots[i]
		if slot == null:
			continue
		var hero_id: int = int(slot)
		if hero_id > 0:
			selected_heroes.append(hero_id)

	if selected_heroes.is_empty():
		# Fallback safety: bail out to playfield if no squad.
		get_tree().change_scene_to_file("res://features/play_field/scenes/play_field.tscn")
		return

	var raw_mission: Variant = GameState.arrayMissions[GameState.intMissionSelected]
	if raw_mission == null:
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")
		return
	mission_data = raw_mission
	xp_reward = int(mission_data.get("intXp", 0))

	mission_enemies.clear()
	var raw_enemies: Variant = mission_data.get("arrayEnemies", null)
	if raw_enemies != null:
		for v in raw_enemies:
			if v == null:
				continue
			var eid: int = int(v)
			if eid > 0:
				mission_enemies.append(eid)
			if mission_enemies.size() == 3:
				break
	while mission_enemies.size() < 3:
		mission_enemies.append(1)

func _build_fighter_lines():
	left_fighters.clear()
	right_fighters.clear()

	for i in range(selected_heroes.size()):
		var hero_id: int = selected_heroes[i]
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if not hero_textures.has(hero_id):
			hero_textures[hero_id] = load(str(hero.get("texture_path", "")))
		left_fighters.append({
			"hero_id": hero_id,
			"base": Vector2(LEFT_X[i + 1] + COMBAT_CENTER_SHIFT, FIGHT_Y),
			"pos": Vector2(LEFT_X[i + 1] + COMBAT_CENTER_SHIFT, FIGHT_Y),
			"alpha": 1.0,
			"fade": false,
			"jump": false,
			"hspd": 0.0,
			"vspd": 0.0,
			"is_attacking": false,
			"attack_dir": 1,
			"visible": true,
			"tex": hero_textures.get(hero_id, null)
		})

	for i in range(3):
		var enemy_id: int = mission_enemies[i]
		var raw_enemy: Variant = GameState.arrayEnemies[enemy_id]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if not enemy_textures.has(enemy_id):
			enemy_textures[enemy_id] = load(str(enemy.get("texture_path", "")))
		right_fighters.append({
			"enemy_id": enemy_id,
			"base": Vector2(RIGHT_X[i + 1] + COMBAT_CENTER_SHIFT, FIGHT_Y),
			"pos": Vector2(RIGHT_X[i + 1] + COMBAT_CENTER_SHIFT, FIGHT_Y),
			"alpha": 1.0,
			"fade": false,
			"hspd": 0.0,
			"is_attacking": false,
			"attack_dir": -1,
			"visible": true,
			"tex": enemy_textures.get(enemy_id, null)
		})

func _setup_ambient_fx():
	# GameMaker fight room had marker spawns commented out; keep this screen clean.
	pass

func _update_layout_to_viewport():
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = min(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	scale = Vector2(fit_scale, fit_scale)
	position = (viewport_size - (DESIGN_SIZE * fit_scale)) * 0.5

func _process(delta: float):
	_update_layout_to_viewport()
	_update_hover_state()
	_update_starfield_state(delta)
	_update_fighter_motion(delta)
	_update_battle_timeline(delta)
	queue_redraw()

func _update_hover_state():
	hovered_return_button = false
	if not return_visible:
		return
	var local_mouse: Vector2 = to_local(get_viewport().get_mouse_position())        
	hovered_return_button = _get_return_button_rect().has_point(local_mouse)

func _update_starfield_state(_delta: float):
	# Keep fight-room acceleration effect while shared manager handles actual spawning.
	if GameState.star_speed < 14.0:
		GameState.star_speed = min(14.0, GameState.star_speed * 1.05)
		GameState.star_size = min(10.0, GameState.star_size * 1.05)

func _update_fighter_motion(delta: float):
	motion_step_accumulator += delta * 60.0
	var steps_to_run: int = mini(int(motion_step_accumulator), 8)
	if steps_to_run <= 0:
		return
	motion_step_accumulator -= float(steps_to_run)

	for _step in range(steps_to_run):
		_simulate_fighter_motion_step()

func _simulate_fighter_motion_step():
	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if bool(f.get("is_attacking", false)):
			_simulate_horizontal_bump(f)
		if bool(f.get("jump", false)):
			_simulate_vertical_jump(f)
		if bool(f.get("fade", false)):
			f["alpha"] = max(0.0, float(f.get("alpha", 1.0)) - 0.025)
			if float(f["alpha"]) <= 0.0:
				f["visible"] = false
		left_fighters[i] = f

	for i in range(right_fighters.size()):
		var f2: Dictionary = right_fighters[i]
		if bool(f2.get("is_attacking", false)):
			_simulate_horizontal_bump(f2)
		if bool(f2.get("fade", false)):
			f2["alpha"] = max(0.0, float(f2.get("alpha", 1.0)) - 0.025)
			if float(f2["alpha"]) <= 0.0:
				f2["visible"] = false
		right_fighters[i] = f2

func _simulate_horizontal_bump(f: Dictionary):
	var pos: Vector2 = f["pos"]
	var base: Vector2 = f["base"]
	var hspd: float = float(f.get("hspd", 0.0))
	var attack_dir: int = int(f.get("attack_dir", 1))

	if not is_equal_approx(pos.x, base.x):
		hspd += -1.7

	for _px in range(int(abs(hspd))):
		if attack_dir > 0:
			if is_equal_approx(pos.x, base.x - 1.0):
				break
			pos.x += signf(hspd)
		else:
			if is_equal_approx(pos.x, base.x + 1.0):
				break
			pos.x -= signf(hspd)

	f["hspd"] = hspd
	f["pos"] = pos

	if absf(pos.x - base.x) <= 1.0 and hspd <= 0.0:
		f["pos"] = base
		f["hspd"] = 0.0
		f["is_attacking"] = false

func _simulate_vertical_jump(f: Dictionary):
	var pos: Vector2 = f["pos"]
	var base: Vector2 = f["base"]
	var vspd: float = float(f.get("vspd", 0.0))

	if not is_equal_approx(pos.y, base.y):
		vspd += 0.5
	else:
		vspd = -10.0

	for _py in range(int(abs(vspd))):
		if is_equal_approx(pos.y, base.y + 1.0):
			vspd = 0.0
			pos.y = base.y
			break
		pos.y += signf(vspd)

	f["vspd"] = vspd
	f["pos"] = pos

func _update_battle_timeline(delta: float):
	if not battle_started or battle_finished:
		if post_victory_timer > 0.0:
			post_victory_timer -= delta
			if post_victory_timer <= 0.0:
				reward_visible = true
				for i in range(left_fighters.size()):
					var f: Dictionary = left_fighters[i]
					if bool(f.get("visible", true)):
						f["jump"] = true
						f["jump_t"] = 0.0
						left_fighters[i] = f
		return

	if pending_hit:
		hit_timer -= delta
		if hit_timer > 0.0:
			return
		_resolve_pending_hit()
		action_timer = CHAIN_DELAY
		pending_hit = false
		return

	if group_fade_timer > 0.0:
		group_fade_timer -= delta
		if group_fade_timer <= 0.0:
			for i in range(right_fighters.size()):
				var target: Dictionary = right_fighters[i]
				if bool(target.get("visible", true)):
					target["fade"] = true
					right_fighters[i] = target
			enemies_left = 0
			return_visible = true
			battle_finished = true
			post_victory_timer = VICTORY_POST_DELAY
		return

	action_timer -= delta
	if action_timer > 0.0:
		return

	if win_flag:
		_progress_win_sequence()
	else:
		_progress_lose_sequence()

func _progress_win_sequence():
	# Heroes strike enemies in order; then remaining enemies fade as a group.
	if strike_index < left_fighters.size() and strike_index < right_fighters.size():
		var attacker: Dictionary = left_fighters[strike_index]
		if bool(attacker.get("visible", true)):
			attacker["is_attacking"] = true
			attacker["hspd"] = 20.0
			attacker["attack_dir"] = 1
			left_fighters[strike_index] = attacker
		pending_hit = true
		hit_timer = IMPACT_DELAY
		pending_attack_from_left = true
		pending_target_index = strike_index
		return

	if enemies_left > 0:
		# GameMaker alarm[9] branch: delayed group fade after final strike.
		group_fade_timer = GROUP_FADE_DELAY
		return

	return_visible = true
	battle_finished = true
	post_victory_timer = VICTORY_POST_DELAY
	return

func _progress_lose_sequence():
	# Enemies strike heroes in order; heroes fade out.
	if strike_index < right_fighters.size() and strike_index < left_fighters.size():
		var attacker: Dictionary = right_fighters[strike_index]
		if bool(attacker.get("visible", true)):
			attacker["is_attacking"] = true
			attacker["hspd"] = 20.0
			attacker["attack_dir"] = -1
			right_fighters[strike_index] = attacker
		pending_hit = true
		hit_timer = IMPACT_DELAY
		pending_attack_from_left = false
		pending_target_index = strike_index
		return

	_finish_battle(false)

func _resolve_pending_hit():
	if pending_attack_from_left:
		if pending_target_index >= 0 and pending_target_index < right_fighters.size():
			var target: Dictionary = right_fighters[pending_target_index]
			if bool(target.get("visible", true)):
				target["fade"] = true
				right_fighters[pending_target_index] = target
				enemies_left -= 1
		strike_index += 1
		if enemies_left <= 0:
			return_visible = true
			battle_finished = true
			post_victory_timer = VICTORY_POST_DELAY
	else:
		if pending_target_index >= 0 and pending_target_index < left_fighters.size():
			var victim: Dictionary = left_fighters[pending_target_index]
			if bool(victim.get("visible", true)):
				victim["fade"] = true
				left_fighters[pending_target_index] = victim
		strike_index += 1
		if strike_index >= left_fighters.size():
			_finish_battle(false)

func _finish_battle(player_won: bool):
	battle_finished = true
	return_visible = true
	reward_visible = false
	if player_won:
		post_victory_timer = VICTORY_POST_DELAY

func _apply_level_up_rewards():
	for i in range(1, 4):
		var hero_slot: Variant = GameState.arrayEngageSlots[i]
		if hero_slot == null:
			continue
		var hero_id: int = int(hero_slot)
		if hero_id <= 0:
			continue
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var new_xp: int = int(hero.get("intXp", 0)) + xp_reward
		hero["intXp"] = new_xp
		var level: int = int(hero.get("intLevel", 1))
		if level + 1 < GameState.arrayLevels.size() and new_xp >= int(GameState.arrayLevels[level + 1]):
			hero["intLevel"] = level + 1
		GameState.arrayHeroes[hero_id] = hero

	# Equivalent of mainData.intXp and mission clear in levelUp.gml.
	GameState.arrayMissions[GameState.intMissionSelected] = null

func _input(event: InputEvent):
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var me: InputEventMouseButton = event

	if me.button_index == MOUSE_BUTTON_RIGHT:
		_return_to_mission_select()
		return

	if me.button_index != MOUSE_BUTTON_LEFT:
		return

	if not return_visible:
		return
	var local_p: Vector2 = to_local(me.position)
	if _get_return_button_rect().has_point(local_p):
		_return_to_mission_select()

func _return_to_mission_select():
	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

func _draw():
	_draw_title()
	_draw_lines()
	_draw_return_button()
	_draw_result_banner()
	_draw_star_debug_counts()

func _draw_title():
	if arcade_font == null:
		return
	_draw_centered_shadowed_text("BATTLE", Vector2(TEXT_CENTER_X, TITLE_Y), 24, Color.WHITE)

func _draw_lines():
	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if not bool(f.get("visible", true)):
			continue
		var rect: Rect2 = Rect2(Vector2(f["pos"]) - CARD_SIZE * 0.5, CARD_SIZE)
		var tex: Texture2D = f.get("tex", null)
		if tex != null:
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, float(f.get("alpha", 1.0))))
		else:
			draw_rect(rect, Color(0.3, 0.3, 0.3, float(f.get("alpha", 1.0))), true)

		if reward_visible:
			var reward_anchor: Vector2 = Vector2(LEFT_X[i + 1] + COMBAT_CENTER_SHIFT - (CARD_SIZE.x * 0.5), REWARD_Y)
			var reward_text: String = "%d XP" % xp_reward
			draw_string(arcade_font, reward_anchor + Vector2(13, 37), reward_text, HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color(0, 0, 1))
			draw_string(arcade_font, reward_anchor + Vector2(10, 34), reward_text, HORIZONTAL_ALIGNMENT_LEFT, 176, 24, Color.WHITE)

	for i2 in range(right_fighters.size()):
		var e: Dictionary = right_fighters[i2]
		if not bool(e.get("visible", true)):
			continue
		var rect2: Rect2 = Rect2(Vector2(e["pos"]) - CARD_SIZE * 0.5, CARD_SIZE)
		var tex2: Texture2D = e.get("tex", null)
		if tex2 != null:
			draw_texture_rect(tex2, rect2, false, Color(1, 1, 1, float(e.get("alpha", 1.0))))
		else:
			draw_rect(rect2, Color(0.3, 0.3, 0.3, float(e.get("alpha", 1.0))), true)

func _draw_return_button():
	if arcade_font == null:
		return
	var r: Rect2 = _get_return_button_rect()
	var tint: Color = Color(1, 1, 1, 1.0 if return_visible else 0.65)
	if hovered_return_button:
		draw_rect(r.grow(3), Color(0.4, 0.7, 1.0, 0.9), false, 2.0)
	if next_button_texture != null:
		draw_texture_rect(next_button_texture, r, false, tint)
	else:
		draw_rect(r, Color.WHITE, false, 2.0)
	draw_string(arcade_font, r.position + Vector2(26, 104), "RETURN", HORIZONTAL_ALIGNMENT_LEFT, 150, 22, Color.WHITE)

func _draw_result_banner():
	if arcade_font == null:
		return
	if not battle_finished:
		_draw_centered_shadowed_text("RESOLVING...", Vector2(TEXT_CENTER_X, BANNER_Y), 24, Color.WHITE)
		return
	var result_txt: String = "VICTORY" if win_flag else "DEFEAT"
	var c: Color = Color(0.2, 1.0, 0.2) if win_flag else Color(1.0, 0.2, 0.2)
	_draw_centered_shadowed_text(result_txt, Vector2(TEXT_CENTER_X, BANNER_Y), 24, c)

func _get_return_button_rect() -> Rect2:
	return Rect2(RETURN_BUTTON_POS, RETURN_BUTTON_SIZE)

func _draw_star_debug_counts():
	if not show_star_debug_counts:
		return
	if arcade_font == null:
		return
	if not GameState.has_node("/root/StarfieldManager"):
		return

	var manager: Node = GameState.get_node("/root/StarfieldManager")
	if not manager.has_method("get_star_type_counts"):
		return

	var counts: Dictionary = manager.call("get_star_type_counts")
	var fast: int = int(counts.get("fast", 0))
	var mid: int = int(counts.get("mid", 0))
	var slow: int = int(counts.get("slow", 0))
	var total: int = maxi(1, int(counts.get("total", 0)))

	var info: String = "Stars F/M/S: %d/%d/%d  Ratio: %.2f:%.2f:%.2f" % [
		fast,
		mid,
		slow,
		float(fast) / total,
		float(mid) / total,
		float(slow) / total
	]
	draw_string(arcade_font, Vector2(32, 104), info, HORIZONTAL_ALIGNMENT_LEFT, 1200, 16, Color(0.85, 0.95, 1.0, 0.9))

func _draw_centered_shadowed_text(text: String, top_left_center_anchor: Vector2, font_size: int, color: Color):
	var text_size: Vector2 = arcade_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var base_pos: Vector2 = top_left_center_anchor + Vector2(-text_size.x * 0.5, float(font_size))
	draw_string(arcade_font, base_pos + Vector2(3, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.0, 1.0))
	draw_string(arcade_font, base_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
