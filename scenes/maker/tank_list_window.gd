extends PanelContainer

signal save_confirmed(bot_list_total)
signal save_cancelled

@onready var bot_list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/BotListContainer
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer4/CancelButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/HBoxContainer4/SaveButton

var hbox_nodes: Array[HBoxContainer] = []
var spinbox_nodes: Array[SpinBox] = []

var bot_list_total: Array = []

var BATCITY_SMALL_SETTINGS = preload("res://fonts/batcity_settings_small.tres")
var SPINBOX_THEME = preload("res://fonts/spinbox_theme.tres")
var icon_up = load("res://sprites/arrow/up.png")
var icon_up_hover = load("res://sprites/arrow/up.png")
var icon_up_pressed = load("res://sprites/arrow/pressed_up.png")
var icon_up_disabled = load("res://sprites/arrow/disabled_up.png")
var icon_down = load("res://sprites/arrow/down.png")
var icon_down_hover = load("res://sprites/arrow/down.png")
var icon_down_pressed = load("res://sprites/arrow/pressed_down.png")
var icon_down_disabled = load("res://sprites/arrow/disabled_down.png")

func _ready() -> void:
	bot_list_total.resize(100)
	for i in range(100):
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var label = Label.new()
		label.text = "Bot %s:" % (i + 1)
		label.label_settings = BATCITY_SMALL_SETTINGS

		var spinbox = SpinBox.new()
		spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		spinbox.min_value = 1
		spinbox.max_value = 4
		spinbox.step = 1
		spinbox.value = 1
		spinbox.theme = SPINBOX_THEME
		spinbox.add_theme_icon_override("up", icon_up)
		spinbox.add_theme_icon_override("up_hover", icon_up_hover)
		spinbox.add_theme_icon_override("up_pressed", icon_up_pressed)
		spinbox.add_theme_icon_override("up_disabled", icon_up_disabled)
		spinbox.add_theme_icon_override("down", icon_down)
		spinbox.add_theme_icon_override("down_hover", icon_down_hover)
		spinbox.add_theme_icon_override("down_pressed", icon_down_pressed)
		spinbox.add_theme_icon_override("down_disabled", icon_down_disabled)

		hbox.add_child(label)
		hbox.add_child(spinbox)
		bot_list_container.add_child(hbox)

		hbox_nodes.append(hbox)
		spinbox_nodes.append(spinbox)
		bot_list_total[i] = 1

	cancel_button.pressed.connect(_on_cancel_pressed)
	save_button.pressed.connect(_on_save_pressed)
	hide()

func show_popup(total_bots_to_show: int, existing_list: Array):
	if existing_list.size() == 100:
		bot_list_total = existing_list.duplicate()

	for i in range(100):
		if i < total_bots_to_show:
			hbox_nodes[i].visible = true
			spinbox_nodes[i].value = bot_list_total[i]
		else:
			hbox_nodes[i].visible = false
	show()

func _on_cancel_pressed():
	hide()
	save_cancelled.emit()

func _on_save_pressed():
	for i in range(100):
		bot_list_total[i] = int(spinbox_nodes[i].value)

	save_confirmed.emit(bot_list_total)
	hide()
