extends CanvasLayer

@onready var level: Node2D = $".."
@onready var enable_pause_timer: Timer = $EnablePauseTimer
@onready var message: Label = $PanelContainer/Message

var in_transition: bool = true
var enable_pause: bool = true
var in_pause: bool = false

var confirmed_exit: bool = false

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if not enable_pause or in_transition:
		return

	if not in_pause:
		for player in Global.current_level_players:
			if Input.is_action_just_pressed("game%d_pause" % (player + 1)):
				active_pause()
				break

	else:
		for player in Global.current_level_players:
			if Input.is_action_just_pressed("game%d_pause" % (player + 1)):
				disable_pause()
				break

			if Input.is_action_just_pressed("game%d_exit" % (player + 1)):
				if confirmed_exit:
					exit_game()
				else:
					try_exit()
				break

func active_pause():
	in_pause = true
	message.text = "PAUSE"
	confirmed_exit = false
	get_tree().paused = true
	show()
	SoundManager.play_sound("pause_game")
	enable_pause = false
	enable_pause_timer.start()

func disable_pause():
	in_pause = false
	get_tree().paused = false
	hide()
	enable_pause = false
	enable_pause_timer.start()

func try_exit():
	var msg1 = Global.get_translated_text("EXIT THE GAME?")
	var msg2 = Global.get_translated_text("PRESS SELECT AGAIN...")
	message.text = msg1 + "\n" + msg2
	confirmed_exit = true

func exit_game():
	SoundManager.stop_all_sounds()
	in_pause = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _on_enable_pause_timeout() -> void:
	enable_pause = true
