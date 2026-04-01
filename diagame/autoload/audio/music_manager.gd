extends Node

# Music manager singleton for handling background music
var music_player: AudioStreamPlayer
var bgmusic: AudioStream

func _ready():
	# Create persistent audio player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	
	# Load and play background music
	if GameState.play_music:
		# The music will be loaded when the import system processes it
		var music_path = "res://assets/sounds/bgmusic.mp3"
		if ResourceLoader.exists(music_path):
			bgmusic = load(music_path)
			if bgmusic:
				music_player.stream = bgmusic
				music_player.play()
				music_player.set_stream_paused(false)
				# Loop the music
				if music_player.stream:
					music_player.finished.connect(_on_music_finished)

func _on_music_finished():
	# Restart music when it finishes
	music_player.play()

func play_sound(sound_path: String):
	"""Play a one-shot sound effect"""
	var sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	var sound = load(sound_path)
	if sound:
		sound_player.stream = sound
		sound_player.play()
		# Remove the player when done
		sound_player.finished.connect(func(): sound_player.queue_free())
