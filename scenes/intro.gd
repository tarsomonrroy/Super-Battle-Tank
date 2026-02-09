extends Node2D

@onready var title: Label = $Title
@onready var warning: Label = $Warning
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var lang_container: Node2D = $ChooseLanguage

var enable_skip: bool = false
var finished: bool = false

var mshs: Dictionary = {
	"msg1": "msg"
}

var msgs: Dictionary = {
	# ENG
	"english": "This is a fan project, not affiliated with, approved or endorsed by Namco LTD.\n
	This fangame is free, if you paid for it, you were scammed.\n
	BATTLE CITY is a trademark of its respective owner.",
	# ESP
	"espanol": "Este es un proyecto de fans, no afiliado, aprobado ni respaldado por Namco LTD.\n
	Este fangame es gratuito, si pagaste por él, fuiste estafado.\n
	BATTLE CITY es una marca registrada de su respectivo propietario.",
	# PTB
	"portugues": "Este é um projeto de fã, não afiliado, aprovado ou endossado pela Namco LTD.\n
	Este fangame é gratuito, se você pagou por ele, foi enganado.\n
	BATTLE CITY é uma marca registrada de seu respectivo proprietário.",
	# FRC
	"francais": "Ceci est un projet de fans, non affilié, approuvé ou soutenu par Namco LTD.\n
	Ce fangame est gratuit, si vous l’avez payé, vous avez été arnaqué.\n
	BATTLE CITY est une marque déposée de son propriétaire respectif.",
	# DCH
	"deutsch": "Dies ist ein Fanprojekt, das nicht mit Namco LTD. verbunden, genehmigt oder unterstützt wird.\n
	Dieses Fangame ist kostenlos, wenn du dafür bezahlt hast, wurdest du betrogen.\n
	BATTLE CITY ist eine eingetragene Marke des jeweiligen Rechteinhabers.",
	# ITL
	"italiano": "Questo è un progetto realizzato da fan, non affiliato, approvato o supportato da Namco LTD.\n
	Questo fangame è gratuito, se lo hai pagato, sei stato truffato.\n
	BATTLE CITY è un marchio registrato del rispettivo proprietario.",
	# NTL
	"netherlands": "Dit is een fanproject en is niet gelieerd aan, goedgekeurd of ondersteund door Namco LTD.\n
	Deze fangame is gratis, als je ervoor hebt betaald, ben je opgelicht.\n
	BATTLE CITY is een handelsmerk van de respectieve eigenaar.",
	# MGY
	"magyar": "Ez egy rajongói projekt, nem áll kapcsolatban a Namco LTD.-vel, és nem annak jóváhagyásával vagy támogatásával készült.\n
	Ez a fangame ingyenes, ha fizettél érte, átvertek.\n
	A BATTLE CITY a megfelelő tulajdonos védjegye.",
	# TRK
	"turk": "Bu bir hayran projesidir, Namco LTD. ile bağlantılı değildir, onaylanmamış ve desteklenmemiştir.\n
	Bu fangame ücretsizdir, eğer bunun için ödeme yaptıysan, dolandırıldın.\n
	BATTLE CITY, ilgili sahibinin ticari markasıdır.",
	# RSS
	"русский": "Это фанатский проект, не связанный, не одобренный и не поддерживаемый компанией Namco LTD.\n
	Этот фанатский проект распространяется бесплатно, если вы заплатили за него, вас обманули.\n
	BATTLE CITY является товарным знаком соответствующего правообладателя.",
	# GRK
	"ελληνικά": "Αυτό είναι ένα έργο θαυμαστών και δεν συνδέεται, δεν εγκρίνεται ούτε υποστηρίζεται από τη Namco LTD.\n
	Αυτό το fangame είναι δωρεάν· αν πληρώσατε γι’ αυτό, σας εξαπάτησαν.\n
	Το BATTLE CITY είναι εμπορικό σήμα του αντίστοιχου κατόχου του.",
	# IDN
	"bahasaindonesia": "Ini adalah proyek penggemar dan tidak berafiliasi, disetujui, atau didukung oleh Namco LTD.\n
	Fangame ini gratis, jika Anda membayarnya, berarti Anda telah ditipu.\n
	BATTLE CITY adalah merek dagang milik pemiliknya masing-masing.",
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	lang_container.language_selected.connect(_on_language_selected)
	if SettingsManager.first_start:
		choose_language()
	else:
		start_intro()

func _process(_delta: float) -> void:
	if enable_skip and Input.is_action_just_pressed("game1_pause"):
		finish_intro()

func _unhandled_input(event):
	if event is InputEventScreenTouch and event.pressed and enable_skip:
		finish_intro()

func choose_language():
	lang_container.open()

func _on_language_selected(lang: String):
	SettingsManager.language = lang
	SettingsManager.first_start = false
	GameTranslation.set_game_language(lang)
	SettingsManager.save_settings()

	await animation_player.animation_finished
	start_intro()

func start_intro():
	lang_container.visible = false

	warning.text = msgs[SettingsManager.language]
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
