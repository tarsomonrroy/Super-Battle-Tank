# save_level_window.gd
extends PanelContainer

signal save_cancelled
signal save_confirmed(save_data, levelname)

@onready var level_name_edit: LineEdit = $MarginContainer/VBoxContainer/MarginContainer1/HBoxContainer1/MarginContainer/LevelNameEdit
@onready var total_bots_spin: SpinBox = $MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer2/MarginContainer/TotalBotsSpin
@onready var check_quick: CheckBox = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/CheckQuick
@onready var check_manual: CheckBox = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/CheckManual
@onready var spawn_time_spin: SpinBox = $MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer3/MarginContainer/SpawnTimeSpin
@onready var setup_button: Button = $MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer2/BotSetup
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer5/CancelButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/HBoxContainer5/SaveButton

@onready var tank_setup_window: PanelContainer = $"Tank Setup Window"
@onready var tank_list_window: PanelContainer = $"Tank List Window"
@onready var confirm_overwrite: PanelContainer = $"Confirm Overwrite"

var in_sub_popup: bool = false

var bot_list: Array = []

func _ready() -> void:
	setup_button.pressed.connect(_on_setup_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	save_button.pressed.connect(_on_save_pressed)
	level_name_edit.text_changed.connect(_validate_data)

	tank_list_window.save_cancelled.connect(_cancel_active)
	tank_list_window.save_confirmed.connect(_define_active)
	
	tank_setup_window.save_cancelled.connect(_cancel_active)
	tank_setup_window.save_confirmed.connect(_define_active)

	confirm_overwrite.overwrite_confirmed.connect(_proceed_to_save)
	confirm_overwrite.overwrite_cancelled.connect(_proceed_to_cancel)

	populate_bot_list()
	hide()

func show_popup(levelname: String = "custom_level", totalbots: float = 20, spawntime: float = 2.5, botlist: Array = []):
	level_name_edit.text = levelname
	total_bots_spin.value = totalbots
	spawn_time_spin.value = spawntime
	bot_list = botlist
	_validate_data()
	show()

func populate_bot_list():
	for i in range(100):
		bot_list.append(1)

func _on_setup_pressed():
	if check_quick.button_pressed:
		tank_setup_window.show_popup(total_bots_spin.value, bot_list)
		toggle_itens(false)
	elif check_manual.button_pressed:
		tank_list_window.show_popup(total_bots_spin.value, bot_list)
		toggle_itens(false)

func _define_active(new_list: Array):
	toggle_itens(true)
	tank_setup_window.hide()
	tank_list_window.hide()
	bot_list = new_list

func _cancel_active():
	toggle_itens(true)
	tank_setup_window.hide()
	tank_list_window.hide()

func _on_cancel_pressed():
	hide()
	save_cancelled.emit()

func _on_save_pressed():
	if not _validate_data():
		return

	var levelname = level_name_edit.text
	var file_path = get_parent().get_filepath(levelname)
	if FileAccess.file_exists(file_path):
		confirm_overwrite.show_overwrite(levelname)
		toggle_itens(false)
	else:
		_proceed_to_save()

func _proceed_to_save():
	var levelname = level_name_edit.text
	var save_data = {
		"level_name": levelname.to_lower(),
		"total_bots": int(total_bots_spin.value),
		"spawn_speed": spawn_time_spin.value,
		"bot_list": bot_list,
	}
	save_confirmed.emit(save_data, level_name_edit.text)

func _proceed_to_cancel():
	confirm_overwrite.hide()
	toggle_itens(true)

func _validate_data(_text: String = "") -> bool:
	var level_name = level_name_edit.text
	if level_name == "":
		save_button.disabled = true
		return false
	else:
		save_button.disabled = false
		return true

func _on_check_quick_toggled(toggled_on: bool) -> void:
	if toggled_on:
		check_manual.button_pressed = false
	if not toggled_on and not check_manual.button_pressed:
		check_quick.button_pressed = true

func _on_check_manual_toggled(toggled_on: bool) -> void:
	if toggled_on:
		check_quick.button_pressed = false
	if not toggled_on and not check_quick.button_pressed:
		check_manual.button_pressed = true

func toggle_itens(state: bool = false):
	level_name_edit.editable = state
	total_bots_spin.editable = state
	check_quick.disabled = not state
	check_manual.disabled = not state
	spawn_time_spin.editable = state
	setup_button.disabled = not state
	cancel_button.disabled = not state
	save_button.disabled = not state
