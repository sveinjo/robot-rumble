extends Node

# Global singleton for game data (equivalent to GameMaker's mainData/buttonMenu)
var star_speed: float = 2.0
var star_size: float = 1.0
var play_music: bool = true
var deploy_target: String = "win"
var base_overtaken: bool = false

# Mission data (equivalent to mainData.arrayMissions)
var arrayMissions: Array = []

# Hero data (equivalent to mainData.arrayHeroes)
var arrayHeroes: Array = []

# Enemy data (equivalent to mainData.arrayEnemies)
var arrayEnemies: Array = []
var arrayLevels: Array = []
var arrayAbilities: Array = []
var intMissionSelected: int = 0

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

	# Initialize enemy array (1-indexed dictionaries)
	arrayEnemies.resize(8)
	arrayEnemies.fill(null)

	# XP thresholds (1-indexed)
	arrayLevels.resize(11)
	arrayLevels.fill(0)

	# Ability display names (1-indexed)
	arrayAbilities.resize(9)
	arrayAbilities.fill(null)

	seed_progression_data()


func seed_progression_data():
	# D&D-like XP curve from the original game.
	arrayLevels[1] = 0
	arrayLevels[2] = 500
	arrayLevels[3] = 3000
	arrayLevels[4] = 6000
	arrayLevels[5] = 10000
	arrayLevels[6] = 15000
	arrayLevels[7] = 21000
	arrayLevels[8] = 28000
	arrayLevels[9] = 36000
	arrayLevels[10] = 1045000

	arrayAbilities[1] = "Troll"
	arrayAbilities[2] = "Time-Warp"
	arrayAbilities[3] = "Blink"
	arrayAbilities[4] = "Armored"
	arrayAbilities[5] = "Counter-Shot"
	arrayAbilities[6] = "Healing"
	arrayAbilities[7] = "Headshot"
	arrayAbilities[8] = "Multi-Shot"

	arrayEnemies[1] = {
		"name": "Henchbot",
		"ability": 1,
		"texture_path": "res://assets/sprites/henchbot_0.png"
	}
	arrayEnemies[2] = {
		"name": "Bombot",
		"ability": 2,
		"texture_path": "res://assets/sprites/bomb_0.png"
	}
	arrayEnemies[3] = {
		"name": "Electron",
		"ability": 3,
		"texture_path": "res://assets/sprites/electron_0.png"
	}
	arrayEnemies[4] = {
		"name": "McHammer",
		"ability": 4,
		"texture_path": "res://assets/sprites/mchammer_0.png"
	}
	arrayEnemies[5] = {
		"name": "Magnetron",
		"ability": 5,
		"texture_path": "res://assets/sprites/magnetron_0.png"
	}
	arrayEnemies[6] = {
		"name": "Octobot",
		"ability": 6,
		"texture_path": "res://assets/sprites/octobot_0.png"
	}
	arrayEnemies[7] = {
		"name": "Tech Romancer",
		"ability": 7,
		"texture_path": "res://assets/sprites/techromancer_0.png"
	}

	if arrayHeroes[1] == null:
		arrayHeroes[1] = {
			"class": "Chronomancer",
			"skillSlot1": 2,
			"intLevel": 1,
			"intXp": 0,
			"texture_path": "res://assets/sprites/Chronomancer_0.png"
		}
	if arrayHeroes[2] == null:
		arrayHeroes[2] = {
			"class": "Hackbot",
			"skillSlot1": 1,
			"intLevel": 1,
			"intXp": 0,
			"texture_path": "res://assets/sprites/Hackbot_0.png"
		}
	if arrayHeroes[3] == null:
		arrayHeroes[3] = {
			"class": "Hunter",
			"skillSlot1": 5,
			"intLevel": 1,
			"intXp": 0,
			"texture_path": "res://assets/sprites/Hunter_0.png"
		}
	if arrayHeroes[4] == null:
		arrayHeroes[4] = {
			"class": "Scout",
			"skillSlot1": 7,
			"intLevel": 1,
			"intXp": 0,
			"texture_path": "res://assets/sprites/Scout_0.png"
		}
	if arrayHeroes[5] == null:
		arrayHeroes[5] = {
			"class": "Tank",
			"skillSlot1": 4,
			"intLevel": 1,
			"intXp": 0,
			"texture_path": "res://assets/sprites/Tank_0.png"
		}


func ensure_ported_data():
	if arrayHeroes.size() < 6:
		arrayHeroes.resize(6)
	if arrayMissions.size() < 10:
		arrayMissions.resize(10)
		for i in range(10):
			if arrayMissions[i] == null:
				arrayMissions[i] = null
	if arrayEnemies.size() < 8 or arrayLevels.size() < 11 or arrayAbilities.size() < 9:
		initialize_game_data()
		return
	seed_progression_data()

func _process(_delta):
	# Toggle fullscreen with Alt+Enter
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
