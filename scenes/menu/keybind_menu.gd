extends Control

@onready var action_list_p1: VBoxContainer = $PageContainer/MarginContainer/VBoxContainerGeneral/PanelContainer/VBoxContainerP1
@onready var action_list_p2: VBoxContainer = $PageContainer/MarginContainer/VBoxContainerGeneral/PanelContainer/VBoxContainerP2
@onready var action_list_p3: VBoxContainer = $PageContainer/MarginContainer/VBoxContainerGeneral/PanelContainer/VBoxContainerP3
@onready var action_list_p4: VBoxContainer = $PageContainer/MarginContainer/VBoxContainerGeneral/PanelContainer/VBoxContainerP4
@onready var player_keys: Label = $PageContainer/MarginContainer/VBoxContainerGeneral/HBoxContainer/PlayerKeys
@onready var button_left: Button = $PageContainer/MarginContainer/VBoxContainerGeneral/HBoxContainer/ButtonLeft
@onready var button_right: Button = $PageContainer/MarginContainer/VBoxContainerGeneral/HBoxContainer/ButtonRight
@onready var back_menu: Button = $back_menu
@onready var reset_keys: Button = $reset_keys

@onready var input_button_scene = preload("res://scenes/menu/keybind_option.tscn")

var is_remapping = false
var action_to_remap = null
var keybind_container = null
var page: int = 1

var input_actions: Dictionary = {
	"_up" : "MOVE UP",
	"_down" : "MOVE DOWN",
	"_left" : "MOVE LEFT",
	"_right" : "MOVE RIGHT",
	"_shoot" : "SHOOT",
	"_pause" : "PAUSE",
	"_exit" : "EXIT",
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	button_left.pressed.connect(_change_player_keys.bind(-1))
	button_right.pressed.connect(_change_player_keys.bind(1))
	back_menu.pressed.connect(_back_to_menu)
	reset_keys.pressed.connect(_reset_to_default)
	_change_player_keys(0)
	_create_action_list(false)

func _create_action_list(reset: bool):
	if reset:
		InputMap.load_from_project_settings()

	for list in [action_list_p1, action_list_p2, action_list_p3, action_list_p4]:
		for item in list.get_children():
			item.queue_free()
	
	var index = 0
	for action_list in [action_list_p1, action_list_p2, action_list_p3, action_list_p4]:
		index += 1
		for action in input_actions:
			var true_key: String = "game" + str(index) + action
			var container: MarginContainer = input_button_scene.instantiate()
			var action_label: Label = container.find_child("LabelAction")
			var input_label: Label = container.find_child("LabelInput")
			var keybind_button: Button = container.find_child("KeybindButton")

			action_label.text = input_actions[action]

			var events: Array = InputMap.action_get_events(true_key)
			if events.size() > 0:
				var key_name = clear_key_name(events[0].as_text())
				input_label.text = key_name
			else:
				input_label.text = ""

			keybind_button.pressed.connect(_on_input_button_pressed.bind(container, true_key))

			action_list.add_child(container)

func _on_input_button_pressed(container: MarginContainer, action: String):
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		keybind_container = container
		var msg = Global.get_translated_text("PRESS ANY KEY...")
		container.find_child("LabelInput").text = msg

func _input(event: InputEvent):
	if is_remapping:
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or (event is InputEventMouseButton && event.pressed):
			if event is InputEventMouseButton and event.double_click:
				event.double_click = false

			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(keybind_container, event)

			is_remapping = false
			action_to_remap = null
			keybind_container = null
			accept_event()

func _update_action_list(container: MarginContainer, event: InputEvent):
	var key_name = clear_key_name(event.as_text())
	container.find_child("LabelInput").text = key_name
	_save_keybinds(page)

func clear_key_name(keyname: String) -> String:
	var formated_keyname: String = ""
	var regex = RegEx.new()
	regex.compile("\\s*\\([^)]*\\)")
	formated_keyname = regex.sub(keyname, "", true)
	return _verify_joypad_motion(formated_keyname)

func _verify_joypad_motion(key_name: String) -> String:
	if not key_name.begins_with("Joypad Motion on Axis"):
		return key_name

	var parts = key_name.split(" ")
	var axis = parts[4]
	var value = float(parts[7])

	var pos = "1" if value >= 0 else "-1"
	return "Joypad Axis%s %s" % [axis, pos]   

func _change_player_keys(direction: int):
	var limit = 4
	page += direction

	if page < 1:
		page = 1
	elif page > limit:
		page = limit

	if page == 1:
		button_left.self_modulate = Color("4F4F4F")
	else:
		button_left.self_modulate = Color("FFF")

	if page == limit:
		button_right.self_modulate = Color("4F4F4F")
	else:
		button_right.self_modulate = Color("FFF")
	_update_current_page()

func _update_current_page():
	action_list_p1.visible = page == 1
	action_list_p2.visible = page == 2
	action_list_p3.visible = page == 3
	action_list_p4.visible = page == 4
	player_keys.text = "PLAYER " + str(page)

func _reset_to_default():
	_create_action_list(true)
	for i in range(1, 5):
		_save_keybinds(i)

func _back_to_menu():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	MenuState.skip_intro = true
	MenuState.start_in = 4
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _save_keybinds(player: int):
	var binds: Dictionary = {}
	for action in input_actions.keys():
		var true_key: String = "game" + str(player) + action
		var events: Array = InputMap.action_get_events(true_key)
		var data_to_save: Dictionary = {
			"key": "Unknown",
			"guid": "",
			"index": "",
			"device": ""
		}
		if events.size() > 0:
			var event = events[0]
			data_to_save["key"] = _event_to_string(event)
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				data_to_save["guid"] = Input.get_joy_guid(event.device)
				if Input.get_joy_info(event.device).get("steam_input_index") != null:
					data_to_save["index"] = Input.get_joy_info(event.device).get("steam_input_index")
				elif Input.get_joy_info(event.device).get("xinput_index") != null:
					data_to_save["index"] = Input.get_joy_info(event.device).get("xinput_index")
				data_to_save["device"] = Input.get_joy_name(event.device)
			elif event is InputEventKey:
				data_to_save["device"] = "Keyboard"
			elif event is InputEventMouseButton:
				data_to_save["device"] = "Mouse"

		binds[true_key] = data_to_save

	SettingsManager.set_keybinds_inputs(player, binds)
	SettingsManager.save_keybindings()

func _event_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return "Key." + OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		return "Mouse." + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Joy." + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var direction = "+" if event.axis_value >= 0 else "-"
		return "JoyMotion." + str(event.axis) + direction
	return "Unknown"
