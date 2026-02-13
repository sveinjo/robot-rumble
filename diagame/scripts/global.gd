extends Node

# Global singleton for game data (equivalent to GameMaker's mainData/buttonMenu)
var star_speed: float = 2.0
var star_size: float = 1.0
var play_music: bool = true
var deploy_target: String = "win"

# Mission data (equivalent to mainData.arrayMissions)
var arrayMissions: Array = []

# Hero data (equivalent to mainData.arrayHeroes)
var arrayHeroes: Array = []

# Enemy data (equivalent to mainData.arrayEnemies)
var arrayEnemies: Array = []

# UI and event flags
var intEventMarker: int = 0
var speechBubbles: bool = true

var arcade_font: Font

func _ready():
	# Set initial window mode to windowed
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Load the arcade font
	arcade_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	# Initialize arrays
	initialize_game_data()

func initialize_game_data():
	# Initialize mission array (1-9 for 3x3 grid)
	arrayMissions.resize(10)  # Index 0 unused, 1-9 used
	arrayMissions.fill(null)

	# Initialize hero array (1-5 for 5 hero types)
	arrayHeroes.resize(6)  # Index 0 unused, 1-5 used
	arrayHeroes.fill(null)

	# Initialize enemy array (2D array: [index, 0=sprite, 1=ability, 2=name])
	arrayEnemies = []
	for i in range(10):  # 0-9 enemy types
		arrayEnemies.append(["", "", ""])  # [sprite, ability, name]

func _process(_delta):
	# Toggle fullscreen with Alt+Enter
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
