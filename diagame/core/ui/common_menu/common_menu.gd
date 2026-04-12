extends CanvasLayer

const DEFAULT_PANEL_WIDTH := 732.0
const PANEL_ACCELERATION := 4.0
const PANEL_MAX_HIDE_SPEED := 50.0
const MENU_BUTTON_SIZE := Vector2(244, 54)
const ACTION_BUTTON_SIZE := Vector2(176, 176)
const MENU_LABEL_SHADOW := Color(0.05, 0.2, 0.8)
const SAVE_SLOT_1_PATH := "user://savegame_slot1.json"

var panel_open: bool = false
var panel_velocity: float = 0.0
var panel_step_accumulator: float = 0.0
var status_timer: float = 0.0
var panel_width: float = DEFAULT_PANEL_WIDTH

var root_control: Control
var menu_button: TextureButton
var menu_button_label: Label
var status_label: Label
var panel: Control
var panel_back: TextureRect
var btn_start: TextureButton
var btn_load: TextureButton
var btn_save: TextureButton
var btn_exit: TextureButton
var btn_fps: TextureButton
var btn_tick: TextureButton
var btn_vsync: TextureButton

var lbl_fps: Label
var lbl_tick: Label
var lbl_vsync: Label

var menu_bar_texture: Texture2D
var menu_back_texture: Texture2D
var empty_texture: Texture2D
var arcade_font: Font

func _ready():
	layer = 100
	menu_bar_texture = load("res://assets/sprites/MenuBar_0.png")
	menu_back_texture = load("res://assets/sprites/MenuBack_0.png")
	empty_texture = load("res://assets/sprites/Empty_0.png")
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	panel_width = float(menu_back_texture.get_width()) if menu_back_texture != null else DEFAULT_PANEL_WIDTH

	root_control = Control.new()
	root_control.name = "Root"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	panel = Control.new()
	panel.name = "MenuPanel"
	panel.position = Vector2(-panel_width, 0)
	panel.size = Vector2(panel_width, get_viewport().get_visible_rect().size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(panel)

	panel_back = TextureRect.new()
	panel_back.texture = menu_back_texture
	panel_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_back.stretch_mode = TextureRect.STRETCH_KEEP
	panel_back.position = Vector2.ZERO
	panel_back.size = panel.size
	panel_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(panel_back)

	menu_button = TextureButton.new()
	menu_button.name = "MenuButton"
	menu_button.position = Vector2.ZERO
	menu_button.size = MENU_BUTTON_SIZE
	menu_button.texture_normal = menu_bar_texture
	menu_button.texture_pressed = menu_bar_texture
	menu_button.texture_hover = menu_bar_texture
	menu_button.stretch_mode = TextureButton.STRETCH_KEEP
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_button.z_index = 10
	menu_button.pressed.connect(_on_menu_pressed)
	root_control.add_child(menu_button)

	menu_button_label = _create_button_label("MENU", 24, MENU_BUTTON_SIZE)
	menu_button.add_child(menu_button_label)

	status_label = _create_label("", Vector2(MENU_BUTTON_SIZE.x + 18.0, 16), 18)
	status_label.visible = false
	status_label.size = Vector2(panel_width, 56)
	status_label.z_index = 20
	root_control.add_child(status_label)

	var side_x := 102.0
	var right_x := panel_width - side_x - ACTION_BUTTON_SIZE.x

	# Keep top and bottom rows symmetric inside the textured panel.
	btn_start = _create_action_button("BACK TO TITLE", Vector2(side_x, 143), _on_start_pressed)
	btn_load = _create_action_button("LOAD GAME", Vector2(side_x, 761), _on_load_pressed)
	btn_save = _create_action_button("SAVE GAME", Vector2(right_x, 761), _on_save_pressed)
	btn_exit = _create_action_button("EXIT GAME", Vector2(right_x, 143), _on_exit_pressed)

	# Middle row uses equal spacing between panel edges and each button.
	var perf_gap := (panel_width - (ACTION_BUTTON_SIZE.x * 3.0)) / 4.0
	btn_fps = _create_action_button("", Vector2(perf_gap, 452), _on_fps_pressed)
	btn_tick = _create_action_button("", Vector2((perf_gap * 2.0) + ACTION_BUTTON_SIZE.x, 452), _on_tick_pressed)
	btn_vsync = _create_action_button("", Vector2((perf_gap * 3.0) + (ACTION_BUTTON_SIZE.x * 2.0), 452), _on_vsync_pressed)

	lbl_fps = btn_fps.get_child(0) as Label
	lbl_tick = btn_tick.get_child(0) as Label
	lbl_vsync = btn_vsync.get_child(0) as Label

	panel.add_child(btn_start)
	panel.add_child(btn_load)
	panel.add_child(btn_save)
	panel.add_child(btn_exit)
	panel.add_child(btn_fps)
	panel.add_child(btn_tick)
	panel.add_child(btn_vsync)

	_refresh_performance_buttons()

func _process(delta: float):
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	root_control.size = vp_size
	panel.size.y = vp_size.y
	panel_back.size = Vector2(panel_width, panel.size.y)
	panel.visible = panel_open or panel.position.x > -panel_width + 1.0
	status_label.visible = status_timer > 0.0
	if status_timer > 0.0:
		status_timer = maxf(0.0, status_timer - delta)

	panel_step_accumulator += delta * 60.0
	var steps_to_run := mini(int(panel_step_accumulator), 8)
	if steps_to_run > 0:
		panel_step_accumulator -= float(steps_to_run)
		for _i in range(steps_to_run):
			_simulate_panel_step()

func _simulate_panel_step():
	if panel_open:
		if panel.position.x < 0.0:
			panel_velocity = (0.0 - panel.position.x) * 0.5
			panel.position.x += panel_velocity
			if panel.position.x > -0.5:
				panel.position.x = 0.0
				panel_velocity = 0.0
		else:
			panel.position.x = 0.0
			panel_velocity = 0.0
		return

	if panel_velocity > -PANEL_MAX_HIDE_SPEED:
		panel_velocity -= PANEL_ACCELERATION
	panel.position.x += panel_velocity
	if panel.position.x <= -panel_width:
		panel.position.x = -panel_width
		panel_velocity = 0.0

func _create_action_button(label: String, pos: Vector2, action: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = empty_texture
	b.texture_pressed = empty_texture
	b.texture_hover = empty_texture
	b.stretch_mode = TextureButton.STRETCH_KEEP
	b.position = pos
	b.size = ACTION_BUTTON_SIZE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(action)

	var l := _create_button_label(_stack_words(label), 24, ACTION_BUTTON_SIZE)
	b.add_child(l)
	return b

func _create_button_label(text: String, font_size: int, size: Vector2) -> Label:
	var lbl := _create_label(text, Vector2.ZERO, font_size)
	lbl.size = size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _create_label(text: String, pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", arcade_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", MENU_LABEL_SHADOW)
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _stack_words(text: String) -> String:
	return text.replace(" ", "\n")

func _on_menu_pressed():
	panel_open = not panel_open

func _on_start_pressed():
	panel_open = false
	if ResourceLoader.exists("res://features/credits/scenes/credits_3d.tscn"):
		get_tree().change_scene_to_file("res://features/credits/scenes/credits_3d.tscn")
	elif ResourceLoader.exists("res://features/credits/scenes/credits.tscn"):
		get_tree().change_scene_to_file("res://features/credits/scenes/credits.tscn")

func _on_load_pressed():
	panel_open = false
	if GameState.load_game_state(SAVE_SLOT_1_PATH):
		_set_status("SLOT 1 LOADED", Color(0.2, 1.0, 0.2))
		call_deferred("_load_saved_scene")
	else:
		_set_status("NO SAVE IN SLOT 1", Color(1.0, 0.35, 0.35))

func _on_save_pressed():
	panel_open = false
	if GameState.save_game_state(SAVE_SLOT_1_PATH):
		_set_status("SLOT 1 SAVED", Color(0.2, 1.0, 0.2))
	else:
		_set_status("SAVE FAILED", Color(1.0, 0.35, 0.35))

func _on_exit_pressed():
	get_tree().quit()

func _on_fps_pressed():
	var caps := PackedInt32Array([0, 30, 60, 120, 144, 240])
	var current: int = int(GameState.fps_cap)
	var idx: int = caps.find(current)
	if idx < 0:
		idx = 0
	else:
		idx = (idx + 1) % caps.size()
	GameState.set_fps_cap(caps[idx])
	_refresh_performance_buttons()
	_set_status("FPS CAP: %s" % ("OFF" if GameState.fps_cap == 0 else str(GameState.fps_cap)), Color(0.85, 0.95, 1.0))

func _on_tick_pressed():
	var rates := PackedInt32Array([30, 60, 120])
	var current: int = int(GameState.physics_tick_rate)
	var idx: int = rates.find(current)
	if idx < 0:
		idx = 0
	else:
		idx = (idx + 1) % rates.size()
	GameState.set_physics_tick_rate(rates[idx])
	_refresh_performance_buttons()
	_set_status("PHYS TICK: %d" % GameState.physics_tick_rate, Color(0.85, 0.95, 1.0))

func _on_vsync_pressed():
	GameState.set_vsync_enabled(not GameState.vsync_enabled)
	_refresh_performance_buttons()
	_set_status("VSYNC: %s" % ("ON" if GameState.vsync_enabled else "OFF"), Color(0.85, 0.95, 1.0))

func _refresh_performance_buttons():
	if lbl_fps != null:
		lbl_fps.text = "FPS\nCAP\n%s" % ("OFF" if GameState.fps_cap == 0 else str(GameState.fps_cap))
	if lbl_tick != null:
		lbl_tick.text = "PHYS\nTICK\n%d" % GameState.physics_tick_rate
	if lbl_vsync != null:
		lbl_vsync.text = "VSYNC\n%s" % ("ON" if GameState.vsync_enabled else "OFF")

func _set_status(text: String, color: Color):
	if status_label == null:
		return
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_timer = 2.0

func _reload_current_scene():
	if get_tree() == null:
		return
	get_tree().reload_current_scene()

func _load_saved_scene():
	if get_tree() == null:
		return
	var saved_scene := GameState.get_saved_scene_path(SAVE_SLOT_1_PATH)
	saved_scene = _normalize_legacy_scene_path(saved_scene)
	if saved_scene.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(saved_scene)

func _normalize_legacy_scene_path(scene_path: String) -> String:
	if scene_path.is_empty():
		return scene_path

	var legacy_map := {
		"res://scenes/mission_select.tscn": "res://features/mission_select/scenes/mission_select.tscn",
		"res://scenes/play_field.tscn": "res://features/play_field/scenes/play_field.tscn",
		"res://scenes/fight_room.tscn": "res://features/fight_room/scenes/fight_room.tscn",
		"res://scenes/home_base.tscn": "res://features/home_base/scenes/home_base.tscn",
		"res://scenes/charge.tscn": "res://features/credits/scenes/charge.tscn",
		"res://scenes/charge_megacharge1.tscn": "res://features/credits/scenes/charge_megacharge1.tscn",
		"res://scenes/click_to_start.tscn": "res://features/credits/scenes/click_to_start.tscn",
		"res://scenes/credits.tscn": "res://features/credits/scenes/credits.tscn",
		"res://scenes/credits_3d.tscn": "res://features/credits/scenes/credits_3d.tscn",
		"res://scenes/credit_fade_text.tscn": "res://features/credits/scenes/credit_fade_text.tscn"
	}

	if legacy_map.has(scene_path):
		return legacy_map[scene_path]
	return scene_path
