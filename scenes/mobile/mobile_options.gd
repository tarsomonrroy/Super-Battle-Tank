extends Control

@onready var visible_controls: Button = $visible_controls
@onready var transparency: Label = $transparency
@onready var plus: Button = $plus
@onready var minus: Button = $minus
@onready var value: Label = $value

var visible_val: float = 0.5

func _ready() -> void:
	MobileControl.control_mode("mobile")
	visible_controls.pressed.connect(change_virtual_buttons_state)
	plus.pressed.connect(change_visibility_value.bind(0.10))
	minus.pressed.connect(change_visibility_value.bind(-0.10))

	visible_val = SettingsManager.virtual_control_visibility
	change_visibility_value(0)
	toggle_virtual_buttons_option()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("game1_exit"):
		SettingsManager.save_settings()
		MobileControl.control_mode("hidden")
		get_tree().change_scene_to_file("res://scenes/menu/keybind_menu.tscn")

func change_virtual_buttons_state():
	SettingsManager.virtual_control_visible = not SettingsManager.virtual_control_visible
	toggle_virtual_buttons_option()

func toggle_virtual_buttons_option():
	if SettingsManager.virtual_control_visible:
		transparency.modulate = Color(1.0, 1.0, 1.0, 1.0)
		value.modulate = Color(1.0, 1.0, 1.0, 1.0)
		disable_transparency_buttons("plus", false)
		disable_transparency_buttons("minus", false)
		MobileControl.toggle_virtual_buttons(true)
		visible_controls.text = GameTranslation.get_translated_text("VIRTUAL BUTTONS ENABLED")
		MobileControl.control_mode("mobile")
		change_visibility_value(0)
	else:
		transparency.modulate = Color(1.0, 1.0, 1.0, 0.3)
		value.modulate = Color(1.0, 1.0, 1.0, 0.3)
		disable_transparency_buttons("plus", true)
		disable_transparency_buttons("minus", true)
		MobileControl.toggle_virtual_buttons(false)
		visible_controls.text = GameTranslation.get_translated_text("VIRTUAL BUTTONS DISABLED")

func change_visibility_value(val: float):
	visible_val += val
	if visible_val <= 0.1:
		visible_val = 0.1
	elif visible_val > 1.0:
		visible_val = 1.0

	var rounded_value = round(visible_val * 10.0) / 10.0
	value.text = "%.0f%%" % (rounded_value * 100)

	MobileControl.set_visibility(rounded_value)
	SettingsManager.virtual_control_visibility = rounded_value

	if rounded_value >= 1.0:
		disable_transparency_buttons("plus", true)
	else:
		disable_transparency_buttons("plus", false)

	if rounded_value <= 0.1:
		disable_transparency_buttons("minus", true)
	else:
		disable_transparency_buttons("minus", false)

func disable_transparency_buttons(button_name: String, state: bool):
	match button_name:
		"plus":
			plus.disabled = state
		"minus":
			minus.disabled = state
