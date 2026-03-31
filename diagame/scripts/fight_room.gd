extends Node2D

const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_SIZE := Vector2(176, 176)
const LEFT_X: Array[int] = [0, 730, 506, 282]
const RIGHT_X: Array[int] = [0, 1014, 1238, 1462]
const FIGHT_Y := 452.0
const REWARD_Y := 652.0
const RETURN_BUTTON_POS := Vector2(1563, 761)
const RETURN_BUTTON_SIZE := Vector2(176, 88)
const TITLE_POS := Vector2(1160, 44)
const START_DELAY := 40.0 / 60.0
const IMPACT_DELAY := 20.0 / 60.0
const CHAIN_DELAY := 60.0 / 60.0
const VICTORY_POST_DELAY := 80.0 / 60.0

var arcade_font: Font
var frame_texture: Texture2D
var flare_texture: Texture2D
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
var reward_visible: bool = false
var xp_reward: int = 0

var action_timer: float = 0.0
var hit_timer: float = 0.0
var post_victory_timer: float = 0.0
var pending_hit: bool = false
var pending_attack_from_left: bool = true
var pending_target_index: int = -1

func _ready():
	randomize()
	Global.ensure_ported_data()
	arcade_font = Global.arcade_font if Global.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	frame_texture = load("res://assets/sprites/Frame_0.png")
	flare_texture = load("res://assets/sprites/Flare.png")

	_load_mission_state()
	_build_fighter_lines()
	_setup_ambient_fx()
	_update_layout_to_viewport()

	# Match GM flow: determine win/loss right after entering fight room.
	var roll := randi_range(0, 100)
	win_flag = roll <= int(round(Global.intBattleWinChance))
	Global.winFlag = 1 if win_flag else 0

	if win_flag:
		_apply_level_up_rewards()

	strike_index = 0
	enemies_left = right_fighters.size()
	action_timer = START_DELAY
	hit_timer = 0.0
	post_victory_timer = 0.0
	pending_hit = false
	battle_started = true
	queue_redraw()

func _load_mission_state():
	selected_heroes.clear()
	for i in range(1, 4):
		var slot: Variant = Global.arrayEngageSlots[i]
		if slot == null:
			continue
		var hero_id := int(slot)
		if hero_id > 0:
			selected_heroes.append(hero_id)

	if selected_heroes.is_empty():
		# Fallback safety: bail out to playfield if no squad.
		get_tree().change_scene_to_file("res://scenes/play_field.tscn")
		return

	var raw_mission: Variant = Global.arrayMissions[Global.intMissionSelected]
	if raw_mission == null:
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
		return
	mission_data = raw_mission
	xp_reward = int(mission_data.get("intXp", 0))

	mission_enemies.clear()
	var raw_enemies: Variant = mission_data.get("arrayEnemies", null)
	if raw_enemies != null:
		for v in raw_enemies:
			if v == null:
				continue
			var eid := int(v)
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
		var hero_id := selected_heroes[i]
		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if not hero_textures.has(hero_id):
			hero_textures[hero_id] = load(str(hero.get("texture_path", "")))
		left_fighters.append({
			"hero_id": hero_id,
			"base": Vector2(LEFT_X[i + 1], FIGHT_Y),
			"pos": Vector2(LEFT_X[i + 1], FIGHT_Y),
			"alpha": 1.0,
			"fade": false,
			"jump": false,
			"jump_t": 0.0,
			"dash_t": 0.0,
			"dashing": false,
			"visible": true,
			"tex": hero_textures.get(hero_id, null)
		})

	for i in range(3):
		var enemy_id := mission_enemies[i]
		var raw_enemy: Variant = Global.arrayEnemies[enemy_id]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if not enemy_textures.has(enemy_id):
			enemy_textures[enemy_id] = load(str(enemy.get("texture_path", "")))
		right_fighters.append({
			"enemy_id": enemy_id,
			"base": Vector2(RIGHT_X[i + 1], FIGHT_Y),
			"pos": Vector2(RIGHT_X[i + 1], FIGHT_Y),
			"alpha": 1.0,
			"fade": false,
			"dash_t": 0.0,
			"dashing": false,
			"visible": true,
			"tex": enemy_textures.get(enemy_id, null)
		})

func _setup_ambient_fx():
	var marker := Sprite2D.new()
	marker.position = Vector2(1651, 849)
	marker.texture = flare_texture
	marker.script = load("res://scripts/marker.gd")
	marker.z_index = 20
	add_child(marker)

	var marker2 := Sprite2D.new()
	marker2.position = Vector2(1651, 849)
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
	_update_starfield_state(delta)
	_update_fighter_motion(delta)
	_update_battle_timeline(delta)
	queue_redraw()

func _update_starfield_state(_delta: float):
	# Keep fight-room acceleration effect while shared manager handles actual spawning.
	Global.star_speed = min(14.0, Global.star_speed * 1.003)
	Global.star_size = min(10.0, Global.star_size * 1.003)

func _update_fighter_motion(delta: float):
	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if bool(f.get("dashing", false)):
			var t: float = float(f.get("dash_t", 0.0)) + (delta * 4.0)
			if t >= 1.0:
				t = 0.0
				f["dashing"] = false
				f["pos"] = f["base"]
			else:
				var base: Vector2 = f["base"]
				var peak: Vector2 = base + Vector2(120.0, 0.0)
				if t < 0.5:
					f["pos"] = base.lerp(peak, t * 2.0)
				else:
					f["pos"] = peak.lerp(base, (t - 0.5) * 2.0)
			f["dash_t"] = t
		if bool(f.get("jump", false)):
			var jt: float = float(f.get("jump_t", 0.0)) + (delta * 2.8)
			var b: Vector2 = f["base"]
			f["pos"] = b + Vector2(0.0, -abs(sin(jt * PI * 2.0)) * 28.0)
			f["jump_t"] = jt
		if bool(f.get("fade", false)):
			f["alpha"] = max(0.0, float(f.get("alpha", 1.0)) - (delta * 1.5))
			if float(f["alpha"]) <= 0.0:
				f["visible"] = false
		left_fighters[i] = f

	for i in range(right_fighters.size()):
		var f2: Dictionary = right_fighters[i]
		if bool(f2.get("dashing", false)):
			var t2: float = float(f2.get("dash_t", 0.0)) + (delta * 4.0)
			if t2 >= 1.0:
				t2 = 0.0
				f2["dashing"] = false
				f2["pos"] = f2["base"]
			else:
				var b2: Vector2 = f2["base"]
				var peak2: Vector2 = b2 + Vector2(-120.0, 0.0)
				if t2 < 0.5:
					f2["pos"] = b2.lerp(peak2, t2 * 2.0)
				else:
					f2["pos"] = peak2.lerp(b2, (t2 - 0.5) * 2.0)
			f2["dash_t"] = t2
		if bool(f2.get("fade", false)):
			f2["alpha"] = max(0.0, float(f2.get("alpha", 1.0)) - (delta * 1.5))
			if float(f2["alpha"]) <= 0.0:
				f2["visible"] = false
		right_fighters[i] = f2

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
			attacker["dashing"] = true
			attacker["dash_t"] = 0.0
			left_fighters[strike_index] = attacker
		pending_hit = true
		hit_timer = IMPACT_DELAY
		pending_attack_from_left = true
		pending_target_index = strike_index
		return

	if enemies_left > 0:
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

func _progress_lose_sequence():
	# Enemies strike heroes in order; heroes fade out.
	if strike_index < right_fighters.size() and strike_index < left_fighters.size():
		var attacker: Dictionary = right_fighters[strike_index]
		if bool(attacker.get("visible", true)):
			attacker["dashing"] = true
			attacker["dash_t"] = 0.0
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
		var hero_slot: Variant = Global.arrayEngageSlots[i]
		if hero_slot == null:
			continue
		var hero_id := int(hero_slot)
		if hero_id <= 0:
			continue
		var raw_hero: Variant = Global.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var new_xp := int(hero.get("intXp", 0)) + xp_reward
		hero["intXp"] = new_xp
		var level := int(hero.get("intLevel", 1))
		if level + 1 < Global.arrayLevels.size() and new_xp >= int(Global.arrayLevels[level + 1]):
			hero["intLevel"] = level + 1
		Global.arrayHeroes[hero_id] = hero

	# Equivalent of mainData.intXp and mission clear in levelUp.gml.
	Global.arrayMissions[Global.intMissionSelected] = null

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
	Global.reset_starfield_defaults()
	get_tree().change_scene_to_file("res://scenes/mission_select.tscn")

func _draw():
	_draw_title()
	_draw_lines()
	_draw_return_button()
	_draw_result_banner()

func _draw_title():
	if arcade_font == null:
		return
	draw_string(arcade_font, TITLE_POS + Vector2(3, 3), "BATTLE", HORIZONTAL_ALIGNMENT_LEFT, 420, 28, Color(0, 0, 1))
	draw_string(arcade_font, TITLE_POS, "BATTLE", HORIZONTAL_ALIGNMENT_LEFT, 420, 28, Color.WHITE)

func _draw_lines():
	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if not bool(f.get("visible", true)):
			continue
		var rect := Rect2(Vector2(f["pos"]) - CARD_SIZE * 0.5, CARD_SIZE)
		var tex: Texture2D = f.get("tex", null)
		if tex != null:
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, float(f.get("alpha", 1.0))))
		else:
			draw_rect(rect, Color(0.3, 0.3, 0.3, float(f.get("alpha", 1.0))), true)
		if frame_texture != null:
			draw_texture_rect(frame_texture, rect, false, Color(1, 1, 1, float(f.get("alpha", 1.0))))

		if reward_visible:
			var reward_rect := Rect2(Vector2(LEFT_X[i + 1] - CARD_SIZE.x * 0.5, REWARD_Y - CARD_SIZE.y * 0.5), CARD_SIZE)
			draw_rect(reward_rect, Color(0.08, 0.08, 0.08, 0.85), true)
			if frame_texture != null:
				draw_texture_rect(frame_texture, reward_rect, false)
			draw_string(arcade_font, reward_rect.position + Vector2(12, 96), "%d XP" % xp_reward, HORIZONTAL_ALIGNMENT_LEFT, 140, 18, Color.WHITE)

	for i2 in range(right_fighters.size()):
		var e: Dictionary = right_fighters[i2]
		if not bool(e.get("visible", true)):
			continue
		var rect2 := Rect2(Vector2(e["pos"]) - CARD_SIZE * 0.5, CARD_SIZE)
		var tex2: Texture2D = e.get("tex", null)
		if tex2 != null:
			draw_texture_rect(tex2, rect2, false, Color(1, 1, 1, float(e.get("alpha", 1.0))))
		else:
			draw_rect(rect2, Color(0.3, 0.3, 0.3, float(e.get("alpha", 1.0))), true)
		if frame_texture != null:
			draw_texture_rect(frame_texture, rect2, false, Color(1, 1, 1, float(e.get("alpha", 1.0))))

func _draw_return_button():
	if arcade_font == null:
		return
	var r := _get_return_button_rect()
	var bg := Color(0.2, 0.6, 0.25, 0.95) if return_visible else Color(0.2, 0.2, 0.2, 0.6)
	draw_rect(r, bg, true)
	draw_rect(r, Color.WHITE, false, 2.0)
	draw_string(arcade_font, r.position + Vector2(34, 52), "RETURN", HORIZONTAL_ALIGNMENT_LEFT, 130, 18, Color.WHITE)

func _draw_result_banner():
	if arcade_font == null:
		return
	if not battle_finished:
		var txt := "RESOLVING..."
		draw_string(arcade_font, Vector2(1110, 96), txt, HORIZONTAL_ALIGNMENT_LEFT, 500, 18, Color(0.9, 0.9, 0.9))
		return
	var result_txt := "VICTORY" if win_flag else "DEFEAT"
	var c := Color(0.2, 1.0, 0.2) if win_flag else Color(1.0, 0.2, 0.2)
	draw_string(arcade_font, Vector2(1110, 96), result_txt, HORIZONTAL_ALIGNMENT_LEFT, 500, 22, c)

func _get_return_button_rect() -> Rect2:
	return Rect2(RETURN_BUTTON_POS, RETURN_BUTTON_SIZE)
