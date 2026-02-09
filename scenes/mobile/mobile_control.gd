extends CanvasLayer

@onready var touch_button_up: TouchScreenButton = $"TouchButton-Up"
@onready var touch_button_left: TouchScreenButton = $"TouchButton-Left"
@onready var touch_button_down: TouchScreenButton = $"TouchButton-Down"
@onready var touch_button_right: TouchScreenButton = $"TouchButton-Right"
@onready var touch_button_shot: TouchScreenButton = $"TouchButton-Shot"
@onready var touch_button_back: TouchScreenButton = $"TouchButton-Back"
@onready var touch_button_pause: TouchScreenButton = $"TouchButton-Pause"
@onready var touch_button_build: TouchScreenButton = $"TouchButton-Build"

var active_controls: bool = true
var visibility_value: float = 0.5

func _ready() -> void:
	set_visibility(SettingsManager.virtual_control_visibility)
	control_mode("hidden")
	if OS.get_name() != "Android":
		active_controls = false

func control_mode(mode_name: String):
	if not active_controls: return
	set_mobile_visibility()
	match mode_name:
		"play":
			toggle_button("TouchButton-Up", true)
			toggle_button("TouchButton-Down", true)
			toggle_button("TouchButton-Left", true)
			toggle_button("TouchButton-Right", true)
			toggle_button("TouchButton-Shot", true)
			toggle_button("TouchButton-Back", false)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("play")
			change_action_buttons("play")
		"pause":
			toggle_button("TouchButton-Up", false)
			toggle_button("TouchButton-Down", false)
			toggle_button("TouchButton-Left", false)
			toggle_button("TouchButton-Right", false)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("play")
			change_action_buttons("play")
		"menu":
			toggle_button("TouchButton-Up", true)
			toggle_button("TouchButton-Down", true)
			toggle_button("TouchButton-Left", true)
			toggle_button("TouchButton-Right", true)
			toggle_button("TouchButton-Shot", true)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("play")
			change_action_buttons("menu")
		"build1":
			toggle_button("TouchButton-Up", false)
			toggle_button("TouchButton-Down", false)
			toggle_button("TouchButton-Left", true)
			toggle_button("TouchButton-Right", true)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", true)
			change_move_buttons("play")
			change_action_buttons("play")
		"build2":
			toggle_button("TouchButton-Up", true)
			toggle_button("TouchButton-Down", true)
			toggle_button("TouchButton-Left", true)
			toggle_button("TouchButton-Right", true)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("editor")
			change_action_buttons("play")
		"build3":
			toggle_button("TouchButton-Up", false)
			toggle_button("TouchButton-Down", false)
			toggle_button("TouchButton-Left", false)
			toggle_button("TouchButton-Right", false)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("editor")
			change_action_buttons("play")
		"language":
			toggle_button("TouchButton-Up", true)
			toggle_button("TouchButton-Down", true)
			toggle_button("TouchButton-Left", false)
			toggle_button("TouchButton-Right", false)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", false)
			toggle_button("TouchButton-Pause", true)
			toggle_button("TouchButton-Build", false)
			change_move_buttons("editor")
			change_action_buttons("menu")
		"mobile":
			toggle_button("TouchButton-Up", false)
			toggle_button("TouchButton-Down", false)
			toggle_button("TouchButton-Left", false)
			toggle_button("TouchButton-Right", false)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", true)
			toggle_button("TouchButton-Pause", false)
			toggle_button("TouchButton-Build", false)
			change_action_buttons("mobile")
		"hidden":
			toggle_button("TouchButton-Up", false)
			toggle_button("TouchButton-Down", false)
			toggle_button("TouchButton-Left", false)
			toggle_button("TouchButton-Right", false)
			toggle_button("TouchButton-Shot", false)
			toggle_button("TouchButton-Back", false)
			toggle_button("TouchButton-Pause", false)
			toggle_button("TouchButton-Build", false)

func change_move_buttons(mode_name: String):
	if not active_controls: return
	match mode_name:
		"play":
			touch_button_up.position = Vector2(40, 152)
			touch_button_down.position = Vector2(40, 216)
			touch_button_left.position = Vector2(8, 184)
			touch_button_right.position = Vector2(72, 184)
		"editor":
			touch_button_up.position = Vector2(208, 80)
			touch_button_down.position = Vector2(208, 144)
			touch_button_left.position = Vector2(176, 112)
			touch_button_right.position = Vector2(240, 112)
			touch_button_up.modulate = Color(1.0, 1.0, 1.0, 1.0)
			touch_button_down.modulate = Color(1.0, 1.0, 1.0, 1.0)
			touch_button_left.modulate = Color(1.0, 1.0, 1.0, 1.0)
			touch_button_right.modulate = Color(1.0, 1.0, 1.0, 1.0)

func change_action_buttons(mode_name: String):
	if not active_controls: return
	match mode_name:
		"play":
			touch_button_shot.position = Vector2(400, 176)
			touch_button_back.position = Vector2(368, 4)
			touch_button_pause.position = Vector2(408, 4)
		"editor":
			touch_button_shot.position = Vector2(400, 176)
			touch_button_back.position = Vector2(352, 4)
			touch_button_pause.position = Vector2(400, 4)
		"menu":
			touch_button_shot.position = Vector2(400, 16)
			touch_button_back.position = Vector2(400, 176)
			touch_button_pause.position = Vector2(400, 216)
		"mobile":
			touch_button_back.position = Vector2(400, 208)

func change_sprite_buttons(mode_name: String):
	if not active_controls: return
	match mode_name:
		"play":
			touch_button_pause.texture_normal = preload("res://sprites/mobile_control/pause-button.png")
		"pause":
			touch_button_pause.texture_normal = preload("res://sprites/mobile_control/unpause-button.png")
		"okay":
			touch_button_pause.texture_normal = preload("res://sprites/mobile_control/okay-button.png")
		"save":
			touch_button_pause.texture_normal = preload("res://sprites/mobile_control/save_button.png")
		"pencil":
			touch_button_build.texture_normal = preload("res://sprites/mobile_control/pencil-button.png")
		"eraser":
			touch_button_build.texture_normal = preload("res://sprites/mobile_control/erase-button.png")
		"shot":
			touch_button_shot.texture_normal = preload("res://sprites/mobile_control/shoot-button.png")
		"score":
			touch_button_shot.texture_normal = preload("res://sprites/mobile_control/score-button.png")

func set_mobile_visibility():
	if not active_controls: return
	touch_button_up.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_down.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_left.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_right.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_shot.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_pause.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_back.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)
	touch_button_build.self_modulate = Color(1.0, 1.0, 1.0, visibility_value)

func toggle_button(btn_name: String, enable: bool):
	if not active_controls: return
	var button = get_node(btn_name)
	if button:
		button.visible = enable

func toggle_virtual_buttons(enable: bool):
	if not active_controls: return
	if enable:
		active_controls = true
	else:
		control_mode("hidden")
		active_controls = false

func set_visibility(value: float):
	if not active_controls: return
	visibility_value = value
	set_mobile_visibility()
