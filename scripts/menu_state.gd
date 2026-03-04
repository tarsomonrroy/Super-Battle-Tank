extends Node

var skip_intro: bool = false
var start_in: int = 1
var last_window_state := DisplayServer.WINDOW_MODE_MAXIMIZED

func _process(_delta: float) -> void:
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED or current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		last_window_state = current_mode

	if Input.is_action_just_pressed("game_fullscreen"):
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(last_window_state)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()
