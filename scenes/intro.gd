extends Node2D

@onready var title: Label = $Title
@onready var warning: Label = $Warning
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var enable_skip: bool = false
var finished: bool = false

func _ready() -> void:
	animation_player.play("RESET")

	animation_player.play("title")
	await animation_player.animation_finished
	await get_tree().create_timer(1.2).timeout

	animation_player.play("title_out")
	await animation_player.animation_finished

	animation_player.play("warning")
	await animation_player.animation_finished
	enable_skip = true
	await get_tree().create_timer(6.5).timeout

	finish_intro()

func _process(_delta: float) -> void:
	if enable_skip and Input.is_action_just_pressed("game1_pause"):
		finish_intro()

func finish_intro():
	if finished: return
	finished = true
	animation_player.play("warning_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
