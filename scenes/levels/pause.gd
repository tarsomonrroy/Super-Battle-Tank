extends CanvasLayer

@onready var level: Node2D = $".."
@onready var enable_pause_timer: Timer = $EnablePauseTimer

var in_transition: bool = true
var enable_pause: bool = true
var in_pause: bool = false

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
				exit_game()
				break

func active_pause():
	in_pause = true
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

func exit_game():
	SoundManager.stop_all_sounds()
	in_pause = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _on_enable_pause_timeout() -> void:
	enable_pause = true
