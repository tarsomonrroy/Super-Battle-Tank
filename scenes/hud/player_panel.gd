extends Control

signal countdown_finished

@onready var player_name: Label = $PlayerName
@onready var total_score: Label = $TotalScore
@onready var total_bot_1: Label = $total_bot1
@onready var total_bot_2: Label = $total_bot2
@onready var total_bot_3: Label = $total_bot3
@onready var total_bot_4: Label = $total_bot4
@onready var total_bots: Label = $total_bots
@onready var bonus_1: Label = $bonus1
@onready var bonus_2: Label = $bonus2

var player_id: int = 1

var bots_target := [0, 0, 0, 0]
var bots_current := [0, 0, 0, 0]
var delay_per_increment := 0.1
var is_skipping: bool = false

func _ready() -> void:
	bonus_1.visible = false
	bonus_2.visible = false
	_reset_labels()

func set_player_number(num: int):
	player_id = num
	player_name.text = "PLAYER " + str(num)

func start_countdown(bots: Dictionary) -> void:
	for i in range(4):
		bots_target[i] = bots.get(i + 1, 0)
		bots_current[i] = 0

	_reset_labels()
	_start_bot_count_sequence()

func _reset_labels() -> void:
	total_bot_1.text = "0"
	total_bot_2.text = "0"
	total_bot_3.text = "0"
	total_bot_4.text = "0"

func _start_bot_count_sequence() -> void:
	await _increment_label(total_bot_1, 0, 20)
	if is_skipping: return
	await get_tree().create_timer(delay_per_increment).timeout
	if is_skipping: return

	await _increment_label(total_bot_2, 1, 30)
	if is_skipping: return
	await get_tree().create_timer(delay_per_increment).timeout
	if is_skipping: return

	await _increment_label(total_bot_3, 2, 40)
	if is_skipping: return
	await get_tree().create_timer(delay_per_increment).timeout
	if is_skipping: return
	
	await _increment_label(total_bot_4, 3, 50)
	if is_skipping: return
	await get_tree().create_timer(delay_per_increment).timeout
	if is_skipping: return

	total_bots.text = "TOTAL: " + str(bots_target.reduce(func(a, b): return a + b))
	countdown_finished.emit()

func _increment_label(label: Label, index: int, bonus: int) -> void:
	var target = bots_target[index]
	while bots_current[index] < target:
		bots_current[index] += 1
		label.text = str(bots_current[index])
		Global.add_score(player_id, bonus)
		update_player_score()
		SoundManager.play_sound("score_bit")
		await get_tree().create_timer(delay_per_increment).timeout

func skip_countdown() -> void:
	if is_skipping: return

	is_skipping = true

	var remaining_score = 0
	remaining_score += (bots_target[0] - bots_current[0]) * 20
	remaining_score += (bots_target[1] - bots_current[1]) * 30
	remaining_score += (bots_target[2] - bots_current[2]) * 40
	remaining_score += (bots_target[3] - bots_current[3]) * 50

	if remaining_score > 0:
		Global.add_score(player_id, remaining_score)
		update_player_score()

	bots_current[0] = bots_target[0]
	bots_current[1] = bots_target[1]
	bots_current[2] = bots_target[2]
	bots_current[3] = bots_target[3]
	total_bot_1.text = str(bots_current[0])
	total_bot_2.text = str(bots_current[1])
	total_bot_3.text = str(bots_current[2])
	total_bot_4.text = str(bots_current[3])

	total_bots.text = "TOTAL: " + str(bots_target.reduce(func(a, b): return a + b))
	countdown_finished.emit()

func bonus_player():
	bonus_1.text = "BONUS!"
	bonus_1.visible = true
	bonus_2.visible = true
	SoundManager.play_sound("best_score")
	Global.add_score(player_id, 1000)
	update_player_score()

func bonus_perfect():
	bonus_1.text = Global.get_translated_text("PERFECT!")
	bonus_1.visible = true
	bonus_2.visible = true
	SoundManager.play_sound("best_score")
	Global.add_score(player_id, 1000)
	update_player_score()

func update_player_score():
	total_score.text = str(Global.get_score(player_id))
