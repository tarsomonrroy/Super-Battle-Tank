extends CanvasLayer

signal finish_results

@onready var level: Node2D = $".."
@onready var results: Node2D = $Results
@onready var level_name: Label = $Results/LevelName
@onready var game_over_screen: Sprite2D = $GameOverScreen

@onready var total_score: Label = $"Results/Total Score"
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var player_1: Control = $Results/PanelContainer/HBoxContainer/Player1
@onready var player_2: Control = $Results/PanelContainer/HBoxContainer/Player2
@onready var player_3: Control = $Results/PanelContainer/HBoxContainer/Player3
@onready var player_4: Control = $Results/PanelContainer/HBoxContainer/Player4
@onready var finish_timer: Timer = $FinishTimer

var p1_bots: Dictionary = { 1: 0, 2: 0, 3: 0, 4: 0 }
var p2_bots: Dictionary = { 1: 0, 2: 0, 3: 0, 4: 0 }
var p3_bots: Dictionary = { 1: 0, 2: 0, 3: 0, 4: 0 }
var p4_bots: Dictionary = { 1: 0, 2: 0, 3: 0, 4: 0 }

var finished: int = 0
var is_counting: bool = false
var is_skipping: bool = false

var PLAYER_PANEL_SCENE = preload("res://scenes/hud/player_panel.tscn")

func _process(_delta: float) -> void:
	if Input.is_action_pressed("game1_pause") and is_counting and not is_skipping:
		is_skipping = true
		if player_1.visible:
			player_1.skip_countdown()
		if player_2.visible:
			player_2.skip_countdown()
		if player_3.visible:
			player_3.skip_countdown()
		if player_4.visible:
			player_4.skip_countdown()

func create_data(levelname: String, levelround: String = "") -> void:
	level_name.text = levelname.to_upper().replace("_", " ") + levelround
	player_1.set_player_number(1)
	player_2.set_player_number(2)
	player_3.set_player_number(3)
	player_4.set_player_number(4)

func start_transition():
	visible = true
	animation.play("close")
	player_1.visible = Global.current_level_players >= 1
	player_2.visible = Global.current_level_players >= 2
	player_3.visible = Global.current_level_players >= 3
	player_4.visible = Global.current_level_players >= 4

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		results.visible = true
		animation.play("open")
		player_1.update_player_score()
		player_2.update_player_score()
		player_3.update_player_score()
		player_4.update_player_score()
		_update_scores()

	elif anim_name == "open":
		is_counting = true
		start_result_menu()

func start_result_menu():
	player_1.start_countdown(p1_bots)
	if Global.current_level_players >= 2:
		player_2.start_countdown(p2_bots)
	if Global.current_level_players >= 3:
		player_3.start_countdown(p3_bots)
	if Global.current_level_players >= 4:
		player_4.start_countdown(p4_bots)

func _countdown_finished():
	finished += 1
	if finished == Global.current_level_players:
		is_counting = false
		finish_general_countdown()

func finish_general_countdown():
	if Global.current_level_players > 1 and not Global.in_game_over:
		set_best_players(Global.current_level_players)
	else:
		await get_tree().create_timer(1.0).timeout
		var total_bots = p1_bots.values().reduce(func(a, b): return a + b)
		if not level.player_hitted and total_bots == level.fixed_total_bots:
			player_1.bonus_perfect()
			await get_tree().create_timer(1.0).timeout
		Global.combine_scores()
		_update_scores()
		SoundManager.play_sound("score_bit")
		finish_timer.start()

func set_best_players(players: int):
	var totals = {
		1: p1_bots.values().reduce(func(a, b): return a + b),
		2: p2_bots.values().reduce(func(a, b): return a + b),
		3: p3_bots.values().reduce(func(a, b): return a + b),
		4: p4_bots.values().reduce(func(a, b): return a + b)
	}

	var active_totals = {}
	for i in range(1, players + 1):
		active_totals[i] = totals[i]

	var max_points = active_totals.values().max()

	var best_players = []
	for id in active_totals.keys():
		if active_totals[id] == max_points:
			best_players.append(id)

	if best_players.size() == 1:
		match best_players[0]:
			1: player_1.bonus_player()
			2: player_2.bonus_player()
			3: player_3.bonus_player()
			4: player_4.bonus_player()

	await get_tree().create_timer(1.0).timeout
	Global.combine_scores()
	_update_scores()
	SoundManager.play_sound("score_bit")
	finish_timer.start()

func _update_scores():
	var msg = Global.get_translated_text("TOTAL SCORE")
	total_score.text = msg + ": " + str(Global.general_score)

func increment_bot_list(player: int, bot: int):
	match player:
		1:
			p1_bots[bot] += 1
		2:
			p2_bots[bot] += 1
		3:
			p3_bots[bot] += 1
		4:
			p4_bots[bot] += 1

func finish_result_screen():
	if not Global.in_game_over:
		finish_results.emit()
	else:
		game_over_screen.visible = true
		SoundManager.play_sound("game_over")
		await get_tree().create_timer(2.0).timeout
		finish_results.emit()
