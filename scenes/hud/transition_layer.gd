extends CanvasLayer

signal transition_finished

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var rect_top: ColorRect = $ColorTop
@onready var rect_bottom: ColorRect = $ColorBottom
@onready var message_string: Label = $LevelName
@onready var round_string: Label = $LevelRound

var is_transitioning: bool = false

func _ready() -> void:
	visible = false

func play_transition_to_scene(scene_path: String, message: String = "— —", music: bool = false, round_level: String = ""):
	if is_transitioning:
		return
	is_transitioning = true
	visible = true

	message = message.replace("_", " ")
	message_string.text = message.to_upper()
	round_string.text = round_level

	anim.play("close")
	await anim.animation_finished
	if music:
		SoundManager.play_sound("level_intro")
	await get_tree().create_timer(0.7).timeout

	if get_tree().current_scene.scene_file_path == scene_path:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame

	anim.play("open")
	await anim.animation_finished

	is_transitioning = false
	visible = false
	message_string.text =  "— —"

	emit_signal("transition_finished")
