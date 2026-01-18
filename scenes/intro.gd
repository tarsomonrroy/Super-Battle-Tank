extends Node2D

@onready var title: Label = $Title
@onready var warning: Label = $Warning
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var lang_container: Node2D = $ChooseLanguage

var enable_skip: bool = false
var finished: bool = false

var msgs: Array = [
	"This is a fan project, not affiliated\n
	with, approved or endorsed by Namco LTD.\n
	\n
	This fangame is free, if you paid\n
	for it, you were scammed.\n
	\n
	BATTLE CITY is a trademark of its\n
	respective owner.",

	"Este es un proyecto de fan,\n
	no afiliado, aprobado ni respaldado\n
	por Namco LTD.\n
	\n
	Este juego es gratuito, si pagaste\n
	por él, te estafaron.\n
	\n
	BATTLE CITY es una marca registrada de\n
	su respectivo propietario.",

	"Este é um projeto feito por fã,\n
	não afiliado, aprovado ou endossado\n
	pela Namco LTD.\n
	\n
	Este fangame é gratuito, se você pagou\n
	por ele, foi enganado.\n
	\n
	BATTLE CITY é uma marca registrada de\n
	seu respectivo proprietário."
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	lang_container.language_selected.connect(_on_language_selected)
	if SettingsManager.first_start:
		choose_language()
	else:
		start_intro()

func choose_language():
	lang_container.open()

func _on_language_selected(lang: String):
	SettingsManager.language = lang
	SettingsManager.first_start = false
	Global.set_game_language(lang)
	SettingsManager.save_settings()

	await animation_player.animation_finished
	start_intro()

func start_intro():
	lang_container.visible = false

	var lng = SettingsManager.language
	
	match lng:
		"english":
			warning.text = msgs[0]
		"espanol":
			warning.text = msgs[1]
		"portugues":
			warning.text = msgs[2]

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

func finish_intro():
	if finished: return
	finished = true
	animation_player.play("warning_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _process(_delta: float) -> void:
	if enable_skip and Input.is_action_just_pressed("game1_pause"):
		finish_intro()
