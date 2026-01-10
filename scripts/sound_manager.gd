extends Node

@onready var cut_tree: AudioStreamPlayer = $"Cut Tree"
@onready var score_bit: AudioStreamPlayer = $"Score Bit"
@onready var enemy_moving: AudioStreamPlayer = $"Enemy Moving"
@onready var player_moving: AudioStreamPlayer = $"Player Moving"
@onready var player_water: AudioStreamPlayer = $"Player Water"
@onready var level_intro: AudioStreamPlayer = $"Level Intro"
@onready var game_over: AudioStreamPlayer = $"Game Over"
@onready var audios: Node = $Audios

var in_game_over: bool = false
var audio_players: Array[AudioStreamPlayer]

func _ready():
	find_audio_players(audios)

func find_audio_players(node: Node):
	for child in node.get_children():
		if child is AudioStreamPlayer:
			audio_players.append(child)
		else:
			find_audio_players(child)

## Play a sound in "res://sounds/" by [param name]
func play_sound(sound_name: String):
	var stop_sounds = false
	if in_game_over:
		stop_sounds = true
		stop_sound("enemy_moving")
		stop_sound("player_moving")
		if sound_name in ["score_bit", "game_over", "one_up", "receive_revive"]:
			stop_sounds = false

	if stop_sounds:
		return

	if sound_name == "enemy_moving":
		if enemy_moving.playing or player_moving.playing: return
		enemy_moving.play()
		return

	if sound_name == "player_moving":
		if player_moving.playing: return
		player_moving.play()
		if enemy_moving.playing:
			enemy_moving.stop()
		return
	
	if sound_name == "player_water":
		if player_water.playing: return
		player_water.play()
		return
	
	if sound_name == "cut_tree":
		if cut_tree.playing: return
		cut_tree.play()
		return
	
	if sound_name == "score_bit":
		if score_bit.playing: return
		score_bit.play()
		return
	
	if sound_name == "level_intro":
		if level_intro.playing: return
		level_intro.play()
		return
		
	if sound_name == "game_over":
		if game_over.playing: return
		game_over.play()
		return
	
	var sound: AudioStream = load("res://sounds/" + sound_name + ".wav")
	if sound == null:
		push_warning("Nenhum AudioStream ", sound_name, " foi encontrado.")
		return

	var player: AudioStreamPlayer = find_idle_player()
	if not player:
		push_warning("Nenhum AudioStream ", sound_name, " foi encontrado.")
		return

	player.stream = sound
	player.play()

## Stop the sound [color=yellow] enemy_moving-player_moving[/color] by [param name]
func stop_sound(sound_name: String):
	if sound_name == "enemy_moving":
		if not enemy_moving.playing: return
		enemy_moving.stop()
		return

	if sound_name == "player_moving":
		if not player_moving.playing: return
		player_moving.stop()
		return

func stop_all_sounds():
	cut_tree.stop()
	enemy_moving.stop()
	player_moving.stop()
	player_water.stop()
	level_intro.stop()

func find_idle_player() -> AudioStreamPlayer:
	for p in audio_players:
		if not p.playing:
			return p
	return null
