extends Node

var config = ConfigFile.new()

const OPTIONS_FILE = "user://settings.ini"

var hard_mode: bool = false
var bot_use_bonus: bool = false
var freeplay_to_campaign: bool = false
var auto_fire: bool = false
var language: String = "english"

var keybinds_p1: Dictionary = {}
var keybinds_p2: Dictionary = {}
var keybinds_p3: Dictionary = {}
var keybinds_p4: Dictionary = {}

func _ready() -> void:
	_load_controller_database()
	load_settings()
	var connected_inputs = Input.get_connected_joypads()
	for input in connected_inputs:
		print("Device ID: ", input)
		print("Device NAME: ", Input.get_joy_name(input))

func _load_controller_database():
	var file_path = "res://gamecontrollerdb.txt"
	if not FileAccess.file_exists(file_path):
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if line.is_empty() or line.begins_with("#"):
			continue
		Input.add_joy_mapping(line)

func load_settings():
	if FileAccess.file_exists(OPTIONS_FILE):
		config.load(OPTIONS_FILE)
		hard_mode = config.get_value("Gameplay", "hard_mode", false)
		bot_use_bonus = config.get_value("Gameplay", "bot_use_bonus", false)
		freeplay_to_campaign = config.get_value("Gameplay", "freeplay_to_campaign", false)
		auto_fire = config.get_value("Gameplay", "auto_fire", false)
		language = config.get_value("Gameplay", "language", "english")
		keybinds_p1 = config.get_value("Keybinding", "keybinds_p1", {})
		keybinds_p2 = config.get_value("Keybinding", "keybinds_p2", {})
		keybinds_p3 = config.get_value("Keybinding", "keybinds_p3", {})
		keybinds_p4 = config.get_value("Keybinding", "keybinds_p4", {})
	else:
		save_settings()
		save_keybindings()

	Global.hard_mode = hard_mode
	Global.bot_use_bonus = bot_use_bonus
	Global.freeplay_to_campaign = freeplay_to_campaign
	Global.auto_fire = auto_fire
	Global.language = language
	Global.set_game_language(language)
	_load_keybinds_into_inputmap()

func save_settings() -> void:
	config.set_value("Gameplay", "hard_mode", hard_mode)
	config.set_value("Gameplay", "bot_use_bonus", bot_use_bonus)
	config.set_value("Gameplay", "freeplay_to_campaign", freeplay_to_campaign)
	config.set_value("Gameplay", "auto_fire", auto_fire)
	config.set_value("Gameplay", "language", language)
	config.save(OPTIONS_FILE)

func save_keybindings() -> void:
	config.set_value("Keybinding", "keybinds_p1", keybinds_p1)
	config.set_value("Keybinding", "keybinds_p2", keybinds_p2)
	config.set_value("Keybinding", "keybinds_p3", keybinds_p3)
	config.set_value("Keybinding", "keybinds_p4", keybinds_p4)
	config.save(OPTIONS_FILE)

func set_keybinds_inputs(player: int, binds: Dictionary):
	match player:
		1:
			keybinds_p1 = binds
		2:
			keybinds_p2 = binds
		3:
			keybinds_p3 = binds
		4:
			keybinds_p4 = binds

func _load_keybinds_into_inputmap():
	var player_keybind_list = [keybinds_p1, keybinds_p2, keybinds_p3, keybinds_p4]
	var assigned_guids_to_devices = {}

	for keybinds in player_keybind_list:
		if keybinds.is_empty():
			continue

		for action_name in keybinds.keys(): # game1_down
			var data = keybinds[action_name]
			var key_text = data.get("key", "Unknown")
			var saved_guid = data.get("guid", "")
			var saved_index= data.get("index", "")
			var target_device_id = -1
			if key_text == "Unknown":
				continue

			if not saved_guid.is_empty() and not saved_index.is_empty():
				var device_key = saved_guid + ":" + saved_index

				if assigned_guids_to_devices.has(device_key):
					target_device_id = assigned_guids_to_devices[device_key]
				else:
					for device_id in Input.get_connected_joypads():
						if Input.get_joy_guid(device_id) == saved_guid:
							if Input.get_joy_info(device_id).get("steam_input_index") != null:
								if Input.get_joy_info(device_id).get("steam_input_index") == saved_index:
									target_device_id = device_id
									assigned_guids_to_devices[device_key] = device_id
									break
							elif Input.get_joy_info(device_id).get("xinput_index") != null:
								if Input.get_joy_info(device_id).get("xinput_index") == saved_index:
									target_device_id = device_id
									assigned_guids_to_devices[device_key] = device_id
									break

			var event = _parse_event_from_text(key_text, target_device_id)
			if event != null:
				InputMap.action_erase_events(action_name)
				InputMap.action_add_event(action_name, event)

func _parse_event_from_text(key_text: String, device_id: int = -1) -> InputEvent:
	var event: InputEvent = null
	if key_text.begins_with("Key."):
		event = InputEventKey.new()
		event.physical_keycode = OS.find_keycode_from_string(key_text.trim_prefix("Key."))

	elif key_text.begins_with("Mouse."):
		event = InputEventMouseButton.new()
		event.button_index = int(key_text.trim_prefix("Mouse."))

	elif key_text.begins_with("Joy."):
		event = InputEventJoypadButton.new()
		event.button_index = int(key_text.trim_prefix("Joy."))
		event.device = device_id

	elif key_text.begins_with("JoyMotion."):
		event = InputEventJoypadMotion.new()
		var part = key_text.trim_prefix("JoyMotion.")
		if part.ends_with("+"):
			event.axis_value = 1.0
			part = part.trim_suffix("+")
		elif part.ends_with("-"):
			event.axis_value = -1.0
			part = part.trim_suffix("-")
		else:
			event.axis_value = 0.0
		var axis = int(part)
		event.axis = axis
		event.device = device_id

	return event
