extends CanvasLayer

const PANEL_WIDTH := 760.0
const PANEL_SPEED := 2200.0
const MENU_BUTTON_SIZE := Vector2(122, 88)
const ACTION_BUTTON_SIZE := Vector2(220, 88)
const MENU_LABEL_SHADOW := Color(0.05, 0.2, 0.8)

var panel_open: bool = false

var root_control: Control
var menu_button: TextureButton
var menu_button_label: Label
var panel: Control
var panel_back: TextureRect
var panel_info_overlay: TextureRect
var btn_start: TextureButton
var btn_load: TextureButton
var btn_save: TextureButton
var btn_exit: TextureButton

var menu_bar_texture: Texture2D
var menu_back_texture: Texture2D
var info_back_texture: Texture2D
var arcade_font: Font

func _ready():
	layer = 100
	menu_bar_texture = load("res://assets/sprites/MenuBar_0.png")
	menu_back_texture = load("res://assets/sprites/MenuBack_0.png")
	info_back_texture = load("res://assets/sprites/InfoBack_0.png")
	arcade_font = Global.arcade_font if Global.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")

	root_control = Control.new()
	root_control.name = "Root"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	menu_button = TextureButton.new()
	menu_button.name = "MenuButton"
	menu_button.position = Vector2.ZERO
	menu_button.size = MENU_BUTTON_SIZE
	menu_button.texture_normal = menu_bar_texture
	menu_button.texture_pressed = menu_bar_texture
	menu_button.texture_hover = menu_bar_texture
	menu_button.stretch_mode = TextureButton.STRETCH_SCALE
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_button.pressed.connect(_on_menu_pressed)
	root_control.add_child(menu_button)

	menu_button_label = _create_label("MENU", Vector2(16, 16), 16)
	menu_button.add_child(menu_button_label)

	panel = Control.new()
	panel.name = "MenuPanel"
	panel.position = Vector2(-PANEL_WIDTH, 0)
	panel.size = Vector2(PANEL_WIDTH, get_viewport().get_visible_rect().size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(panel)

	panel_back = TextureRect.new()
	panel_back.texture = menu_back_texture
	panel_back.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	panel_back.stretch_mode = TextureRect.STRETCH_SCALE
	panel_back.position = Vector2.ZERO
	panel_back.size = panel.size
	panel_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(panel_back)

	panel_info_overlay = TextureRect.new()
	panel_info_overlay.texture = info_back_texture
	panel_info_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_info_overlay.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	panel_info_overlay.position = Vector2(12, 0)
	panel_info_overlay.size = panel.size
	panel_info_overlay.modulate = Color(1, 1, 1, 0.25)
	panel_info_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(panel_info_overlay)

	btn_start = _create_action_button("BACK TO TITLE", Vector2(278, 143), _on_start_pressed)
	btn_load = _create_action_button("LOAD GAME", Vector2(102, 452), _on_load_pressed)
	btn_save = _create_action_button("SAVE GAME", Vector2(454, 452), _on_save_pressed)
	btn_exit = _create_action_button("EXIT GAME", Vector2(278, 761), _on_exit_pressed)

	panel.add_child(btn_start)
	panel.add_child(btn_load)
	panel.add_child(btn_save)
	panel.add_child(btn_exit)

func _process(delta: float):
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	root_control.size = vp_size
	panel.size.y = vp_size.y
	panel_back.size = panel.size
	panel_info_overlay.size = panel.size
	panel.visible = panel_open or panel.position.x > -PANEL_WIDTH + 1.0

	var target_x := 0.0 if panel_open else -PANEL_WIDTH
	panel.position.x = move_toward(panel.position.x, target_x, PANEL_SPEED * delta)

func _create_action_button(label: String, pos: Vector2, action: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = menu_bar_texture
	b.texture_pressed = menu_bar_texture
	b.texture_hover = menu_bar_texture
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = pos
	b.size = ACTION_BUTTON_SIZE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(action)

	var l := _create_label(label, Vector2(16, 16), 16)
	l.size = ACTION_BUTTON_SIZE
	b.add_child(l)
	return b

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
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _on_menu_pressed():
	panel_open = not panel_open

func _on_start_pressed():
	panel_open = false
	if ResourceLoader.exists("res://scenes/credits_3d.tscn"):
		get_tree().change_scene_to_file("res://scenes/credits_3d.tscn")
	elif ResourceLoader.exists("res://scenes/credits.tscn"):
		get_tree().change_scene_to_file("res://scenes/credits.tscn")

func _on_load_pressed():
	panel_open = false
	if Global.load_game_state():
		print("Save loaded")
	else:
		print("No save found")

func _on_save_pressed():
	panel_open = false
	if Global.save_game_state():
		print("Game saved")
	else:
		print("Save failed")

func _on_exit_pressed():
	get_tree().quit()
