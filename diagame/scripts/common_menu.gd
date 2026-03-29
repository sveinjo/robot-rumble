extends CanvasLayer

const PANEL_WIDTH := 760.0
const PANEL_SPEED := 2200.0
const MENU_BUTTON_SIZE := Vector2(122, 88)

var panel_open: bool = false

var root_control: Control
var menu_button: Button
var panel: Panel
var btn_start: Button
var btn_load: Button
var btn_save: Button
var btn_exit: Button

func _ready():
	layer = 100

	root_control = Control.new()
	root_control.name = "Root"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "MENU"
	menu_button.position = Vector2.ZERO
	menu_button.size = MENU_BUTTON_SIZE
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_button.pressed.connect(_on_menu_pressed)
	root_control.add_child(menu_button)

	panel = Panel.new()
	panel.name = "MenuPanel"
	panel.position = Vector2(-PANEL_WIDTH, 0)
	panel.size = Vector2(PANEL_WIDTH, get_viewport().get_visible_rect().size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(panel)

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
	panel.visible = panel_open or panel.position.x > -PANEL_WIDTH + 1.0

	var target_x := 0.0 if panel_open else -PANEL_WIDTH
	panel.position.x = move_toward(panel.position.x, target_x, PANEL_SPEED * delta)

func _create_action_button(label: String, pos: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.position = pos
	b.size = Vector2(220, 88)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(action)
	return b

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
