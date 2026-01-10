extends PanelContainer

signal save_confirmed(bot_list_total)
signal save_cancelled

@onready var total_bots_spin_1: SpinBox = $MarginContainer/VBoxContainer/BotListContainer1/HBoxContainer/TotalBotsSpin1
@onready var total_bots_spin_2: SpinBox = $MarginContainer/VBoxContainer/BotListContainer2/HBoxContainer/TotalBotsSpin2
@onready var total_bots_spin_3: SpinBox = $MarginContainer/VBoxContainer/BotListContainer3/HBoxContainer/TotalBotsSpin3
@onready var total_bots_spin_4: SpinBox = $MarginContainer/VBoxContainer/BotListContainer4/HBoxContainer/TotalBotsSpin4
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer4/CancelButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/HBoxContainer4/SaveButton

var icon_up = load("res://sprites/arrow/up.png")
var icon_up_disabled = load("res://sprites/arrow/disabled_up.png")
var icon_down = load("res://sprites/arrow/down.png")
var icon_down_disabled = load("res://sprites/arrow/disabled_down.png")

var bot_limit: int = 20
var bot_list_total: Array = []

func _ready() -> void:
	bot_list_total.resize(100)
	save_button.disabled = true

	cancel_button.pressed.connect(_on_cancel_pressed)
	save_button.pressed.connect(_on_save_pressed)

func show_popup(total_bots: int, existing_list: Array):
	if existing_list.size() == 100:
		bot_list_total = existing_list.duplicate()
	else:
		bot_list_total.resize(100)
	bot_limit = total_bots

	total_bots_spin_1.value = bot_limit
	total_bots_spin_2.value = 0
	total_bots_spin_3.value = 0
	total_bots_spin_4.value = 0

	_update_spin_limits()
	_update_save_button()
	show()

func _on_spin_changed(_value: float) -> void:
	_update_spin_limits()
	_update_save_button()

func _update_spin_limits():
	var sum = total_bots_spin_1.value + total_bots_spin_2.value + total_bots_spin_3.value + total_bots_spin_4.value
	var remaining = bot_limit - sum

	for spin in [total_bots_spin_1, total_bots_spin_2, total_bots_spin_3, total_bots_spin_4]:
		spin.max_value = spin.value + remaining

	if sum > bot_limit:
		_fix_overflow(sum - bot_limit)

func _fix_overflow(excess: int):
	var spins = [total_bots_spin_4, total_bots_spin_3, total_bots_spin_2, total_bots_spin_1]
	for spin in spins:
		if spin.value > 0:
			var new_value = max(0, spin.value - excess)
			excess -= (spin.value - new_value)
			spin.value = new_value
			if excess <= 0:
				break

func _update_skins_value(spin: SpinBox):
	spin.update_configuration_warnings()

func _update_save_button():
	var total = total_bots_spin_1.value + total_bots_spin_2.value + total_bots_spin_3.value + total_bots_spin_4.value
	save_button.disabled = (total != bot_limit)

func _on_save_pressed():
	var bot_types = [
		[1, total_bots_spin_1.value],
		[2, total_bots_spin_2.value],
		[3, total_bots_spin_3.value],
		[4, total_bots_spin_4.value]
	]

	bot_list_total.clear()
	for type_data in bot_types:
		var bot_type = type_data[0]
		var amount = type_data[1]
		for i in amount:
			bot_list_total.append(bot_type)

	while bot_list_total.size() < 100:
		bot_list_total.append(1)
	
	save_confirmed.emit(bot_list_total)
	hide()

func _on_cancel_pressed():
	hide()
	save_cancelled.emit()
