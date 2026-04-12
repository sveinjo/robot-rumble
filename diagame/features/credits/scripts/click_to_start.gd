extends Node

const NEXT_SCENE_PATH := "res://features/credits/scenes/credits_3d.tscn"

var _music_player: AudioStreamPlayer
var _resume_music_on_exit := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_silence_music_for_staging()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return
		get_viewport().set_input_as_handled()
		_resume_music_if_needed()
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)

func _silence_music_for_staging() -> void:
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager == null:
		return

	var maybe_player = music_manager.get("music_player")
	if maybe_player is AudioStreamPlayer:
		_music_player = maybe_player
		_resume_music_on_exit = _music_player.playing
		if _resume_music_on_exit:
			_music_player.stop()

func _resume_music_if_needed() -> void:
	if _resume_music_on_exit and _music_player != null and _music_player.stream != null:
		_music_player.play()
