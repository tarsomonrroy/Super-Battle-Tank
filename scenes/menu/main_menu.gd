extends Node2D

@onready var option_menu: Sprite2D = $OptionMenu
@onready var player_mode: Label = $Menu/PanelContainer2/Players

@onready var page_1: Node2D = $Page1
@onready var button_container_1: Array = $Page1/PageContainer/VBoxContainer.get_children()
@onready var page_2: Node2D = $Page2
@onready var button_container_2: Array = $Page2/PageContainer/VBoxContainer.get_children()
@onready var page_3: Node2D = $Page3
@onready var button_container_3: Array = $Page3/PageContainer/VBoxContainer.get_children()
@onready var page_4: Node2D = $Page4
@onready var button_container_4: Array = $Page4/PageContainer/VBoxContainer.get_children()
@onready var free_to_campaign_button: Button = $Page4/PageContainer/VBoxContainer/FreeToCampaign
@onready var bot_bonus_button: Button = $Page4/PageContainer/VBoxContainer/BotBonus
@onready var hard_mode_button: Button = $Page4/PageContainer/VBoxContainer/HardMode
@onready var auto_fire: Button = $Page4/PageContainer/VBoxContainer/AutoFire
@onready var language: Button = $Page4/PageContainer/VBoxContainer/Language
@onready var page_5: Node2D = $Page5
@onready var button_container_5: Array = $Page5/PageContainer/VBoxContainerGeneral/VBoxContainer.get_children()
@onready var page_6: Node2D = $Page6
@onready var page6_title: Label = $Page6/PageContainer/VBoxContainer/Title
@onready var page6_score: Label = $Page6/PageContainer/VBoxContainer/LevelScore
@onready var page6_error: Label = $Page6/PageContainer/VBoxContainer/Error
@onready var page_7: Node2D = $Page7
@onready var button_container_7: Array = $Page7/PageContainer/VBoxContainer/HBoxContainer.get_children()

@onready var level_name: Label = $Page6/PageContainer/VBoxContainer/HBoxContainer/LevelName
@onready var to_left: Label = $Page6/PageContainer/VBoxContainer/HBoxContainer/Left
@onready var to_right: Label = $Page6/PageContainer/VBoxContainer/HBoxContainer/Right
@onready var credits_text: Label = $CreditsText

@onready var icon_left: Sprite2D = $IconLeft
@onready var icon_right: Sprite2D = $IconRight
@onready var animation: AnimationPlayer = $AnimationPlayer

@onready var hi_score_title: Label = $Menu/PanelContainer1/HBoxContainer/HiScoreTitle
@onready var hi_score_value_1: Label = $Menu/PanelContainer1/HBoxContainer/HiScoreValue1
@onready var hi_score_value_2: Label = $Menu/PanelContainer1/HBoxContainer/HiScoreValue2
@onready var hi_score_value_3: Label = $Menu/PanelContainer1/HBoxContainer/HiScoreValue3
@onready var hi_score_value_4: Label = $Menu/PanelContainer1/HBoxContainer/HiScoreValue4
@onready var hi_score_timer: Timer = $HiScoreTimer

@onready var initial_delay_timer: Timer = $InitialDelayTimer
@onready var repeat_timer: Timer = $RepeatTimer

var menu_started: bool = false

var held_direction: int = 0

var level_select_list: Array = []
var level_select_index: int = 0

var current_page: Node2D = null
var current_page_buttons: Array = []
var previous_page_index: int = 1

var control_active: bool = false
var current_index: int = 0
var players: int = 1
var tier: int = 1

var start_page: int = 1

var extra_hiscore_title: String = ""

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	current_page = page_1
	for container in [button_container_1, button_container_2, button_container_3, button_container_4, button_container_5, button_container_7]:
		for i in range(container.size()):
			var button = container[i]
			button.pressed.connect(_on_button_pressed.bind(button.name))
	SoundManager.in_game_over = false
	Global.reset_game()
	start_menu(MenuState.skip_intro, MenuState.start_in)
	if Global.hard_mode:
		var dff = " " + Global.get_translated_text("HARD")
		extra_hiscore_title = dff
		change_title()

func start_menu(skip_intro: bool, start_in: int = 1):
	if skip_intro:
		animation.play("finished")
	else:
		animation.play("start")
	start_page = start_in

	MenuState.skip_intro = false
	MenuState.start_in = 1

func _process(_delta: float) -> void:
	if not control_active:
		if menu_started:
			return
		if Input.is_action_just_pressed("game1_pause") or Input.is_action_just_pressed("menu_accept"):
			start_menu(true, 1)
		return
	else:
		if current_page == page_6:
			var just_pressed_direction = 0
			if Input.is_action_just_pressed("game1_right") or Input.is_action_just_pressed("menu_right"):
				just_pressed_direction = 1
			elif Input.is_action_just_pressed("game1_left") or Input.is_action_just_pressed("menu_left"):
				just_pressed_direction = -1
			
			if just_pressed_direction != 0:
				held_direction = just_pressed_direction
				_move_level_selection(held_direction)
				initial_delay_timer.start()
				repeat_timer.stop()
			
			var is_held_button_still_pressed = false
			if held_direction == 1 and (Input.is_action_pressed("game1_right") or Input.is_action_pressed("menu_right")):
				is_held_button_still_pressed = true
			elif held_direction == -1 and (Input.is_action_pressed("game1_left") or Input.is_action_pressed("menu_left")):
				is_held_button_still_pressed = true

			if held_direction != 0 and not is_held_button_still_pressed:
				held_direction = 0
				initial_delay_timer.stop()
				repeat_timer.stop()

			if Input.is_action_just_pressed("game1_pause") or Input.is_action_just_pressed("menu_accept"):
				control_active = false
				_activate_level_selection()
			elif Input.is_action_just_pressed("game1_exit") or Input.is_action_just_pressed("menu_back"):
				SoundManager.play_sound("menu_blocked")
				change_page(previous_page_index)

		else:
			if current_page == page_7:
				if Input.is_action_just_pressed("game1_left") or Input.is_action_just_pressed("menu_left"):
					_move_selection(-1)
				elif Input.is_action_just_pressed("game1_right") or Input.is_action_just_pressed("menu_right"):
					_move_selection(1)
			else:
				if Input.is_action_just_pressed("game1_up") or Input.is_action_just_pressed("menu_up"):
					_move_selection(-1)
				elif Input.is_action_just_pressed("game1_down") or Input.is_action_just_pressed("menu_down"):
					_move_selection(1)

			if Input.is_action_just_pressed("game1_pause") or Input.is_action_just_pressed("menu_accept"):
				_activate_current_option()
			elif Input.is_action_just_pressed("game1_exit") or Input.is_action_just_pressed("menu_back"):
				_back_current_menu()
		
		if Input.is_action_just_pressed("game1_shoot") or Input.is_action_just_pressed("menu_action"):
			if hi_score_timer.is_inside_tree():
				hi_score_timer.start()
			_update_hi_score_texts(1)

func _on_initial_delay_timeout() -> void:
	if held_direction == 0:
		return
	_move_level_selection(held_direction)
	repeat_timer.start()

func _on_repeat_timeout() -> void:
	if held_direction == 0:
		return
	_move_level_selection(held_direction)
	repeat_timer.start()

func _update_hi_score():
	hi_score_value_1.text = Highscore.get_highscore_string(1)
	hi_score_value_2.text = Highscore.get_highscore_string(2)
	hi_score_value_3.text = Highscore.get_highscore_string(3)
	hi_score_value_4.text = Highscore.get_highscore_string(4)

func _on_hi_score_timeout() -> void:
	_update_hi_score_texts(1)
	
func _update_hi_score_texts(value: int = 0) -> void:
	if tier < 4:
		tier += value
	else:
		tier = 1
	change_title()
	hi_score_value_1.visible = tier == 1
	hi_score_value_2.visible = tier == 2
	hi_score_value_3.visible = tier == 3
	hi_score_value_4.visible = tier == 4

func change_title():
	_update_hi_score()
	match tier:
		1:
			var msg = Global.get_translated_text("HIGHSCORE 1P")
			hi_score_title.text = msg + extra_hiscore_title + " -"
		2:
			var msg = Global.get_translated_text("HIGHSCORE 2P")
			hi_score_title.text = msg + extra_hiscore_title + " -"
		3:
			var msg = Global.get_translated_text("HIGHSCORE 3P")
			hi_score_title.text = msg + extra_hiscore_title + " -"
		4:
			var msg = Global.get_translated_text("HIGHSCORE 4P")
			hi_score_title.text = msg + extra_hiscore_title + " -"

func _on_animation_finished(_anim_name: StringName) -> void:
	icon_left.visible = true
	icon_right.visible = true
	hi_score_title.visible = true
	hi_score_timer.start()
	_update_hi_score_texts(0)
	_update_hi_score()
	control_active = true
	menu_started = true
	change_page(start_page)

func _on_button_pressed(button_name: String) -> void:
	match button_name:
		# Page 1
		"PlayGame":
			change_page(2)

		"Options":
			change_page(4)

		"Construction":
			change_page(5)

		"ExitGame":
			change_page(7)

		# Page 2
		"1Player", "2Player", "3Player", "4Player":
			set_player_mode(button_name)
			change_page(3)

		# Page 3
		"Campaign":
			control_active = false
			to_level_scene(Global.GamePlay.CAMPAIGN, "level_1")

		"Freeplay":
			Global.current_gameplay_mode = Global.GamePlay.FREEPLAY
			Global.current_game_mode = Global.GameMode.PLAY
			previous_page_index = 3
			change_page(6)

		"Custom":
			Global.current_gameplay_mode = Global.GamePlay.CUSTOM
			Global.current_game_mode = Global.GameMode.PLAY
			previous_page_index = 3
			change_page(6)
		
		"Survival":
			Global.current_gameplay_mode = Global.GamePlay.SURVIVAL
			Global.current_game_mode = Global.GameMode.PLAY
			previous_page_index = 3
			change_page(6)

		# Page 4
		"HardMode":
			Global.hard_mode = not Global.hard_mode
			SettingsManager.hard_mode = Global.hard_mode
			change_option()

		"BotBonus":
			Global.bot_use_bonus = not Global.bot_use_bonus
			SettingsManager.bot_use_bonus = Global.bot_use_bonus
			change_option()
		
		"FreeToCampaign":
			Global.freeplay_to_campaign = not Global.freeplay_to_campaign
			SettingsManager.freeplay_to_campaign = Global.freeplay_to_campaign
			change_option()
		
		"AutoFire":
			Global.auto_fire = not Global.auto_fire
			SettingsManager.auto_fire = Global.auto_fire
			change_option()
		
		"Language":
			Global.get_next_language()
			SettingsManager.language = Global.language
			change_option()

		"Gamepad":
			get_tree().change_scene_to_file("res://scenes/menu/keybind_menu.tscn")

		# Page 5
		"NewConstruction":
			control_active = false
			to_maker_scene()

		"LoadConstruction":
			Global.current_gameplay_mode = Global.GamePlay.CUSTOM
			Global.current_game_mode = Global.GameMode.MAKER
			previous_page_index = 5
			change_page(6)

		"ExitYes":
			get_tree().quit()

		"ExitNo":
			change_page(1)

func set_player_mode(btn_name: String):
	match btn_name:
		"1Player":
			players = 1
		"2Player":
			players = 2
		"3Player":
			players = 3
		"4Player":
			players = 4

	var msg = Global.get_translated_text(str(players) + " PLAYER MODE")
	player_mode.text = msg

func change_option():
	var msg = Global.get_translated_text("HARD MODE")
	var stt = get_on_off_state(Global.hard_mode)
	var dff = " " + Global.get_translated_text("HARD")
	if not Global.hard_mode: dff = ""
	hard_mode_button.text = msg + " - " + stt
	extra_hiscore_title = dff
	change_title()

	var msg1 = Global.get_translated_text("BOTS USE BONUS")
	var stt1 = get_on_off_state(Global.bot_use_bonus)
	bot_bonus_button.text = msg1 + " - " + stt1

	var msg2 = Global.get_translated_text("FREEPLAY TO CAMPAIGN")
	var stt2 = get_on_off_state(Global.freeplay_to_campaign)
	free_to_campaign_button.text = msg2 + " - " + stt2

	var msg3 = Global.get_translated_text("AUTO FIRE")
	var stt3 = get_on_off_state(Global.auto_fire)
	auto_fire.text = msg3 + " - " + stt3

	var msg4 = Global.get_translated_text("LANGUAGE")
	language.text = msg4 + " - " + Global.get_original_language()

	await get_tree().create_timer(0.001).timeout
	_update_cursor_position()

func get_on_off_state(state: bool) -> String:
	if state:
		return Global.get_translated_text("ON")
	return Global.get_translated_text("OFF")

func to_level_scene(gameplay: Global.GamePlay, filename: String = "", level_num: int = 1):
	Global.current_game_mode = Global.GameMode.PLAY
	Global.current_gameplay_mode = gameplay
	Global.current_level_number = level_num
	Global.current_level_name = filename
	Global.set_player_level(players)

	var survival_round = ""
	if Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		var msg = Global.get_translated_text("ROUND")
		survival_round = "\n" + msg + " " + str(Global.current_level_round)
	LoadingScreen.play_transition_to_scene("res://scenes/levels/level.tscn", Global.current_level_name, true, survival_round)

func to_maker_scene(filename: String = ""):
	Global.current_game_mode = Global.GameMode.MAKER
	Global.current_level_number = -1
	Global.current_level_name = filename
	LoadingScreen.play_transition_to_scene("res://scenes/maker/maker.tscn", "construction")

#region PAGE 1 TO 5

func _move_selection(direction: int) -> void:
	current_index = wrapi(current_index + direction, 0, current_page_buttons.size())
	SoundManager.play_sound("menu_select")
	_update_cursor_position()

func _activate_current_option() -> void:
	var button: Button = current_page_buttons[current_index]
	button.emit_signal("pressed")
	SoundManager.play_sound("menu_accept")
	_update_cursor_position()

func _back_current_menu() -> void:
	if current_page == page_4:
		SettingsManager.save_settings()
	if current_page != page_1:
		SoundManager.play_sound("menu_blocked")
		change_page(1)

func change_page(page: int):
	control_active = false
	current_index = 0
	current_page.modulate = Color(1.0, 1.0, 1.0, 0.0)
	icon_left.visible = true
	icon_right.visible = true
	option_menu.visible = page == 4
	player_mode.visible = false
	match page:
	# Main Menu
		1:
			current_page = page_1
			current_page_buttons = button_container_1

	# Players Choose
		2:
			current_page = page_2
			current_page_buttons = button_container_2

	# Game Menu
		3:
			current_page = page_3
			current_page_buttons = button_container_3
			player_mode.visible = true

	# Options Menu
		4:
			current_page = page_4
			current_page_buttons = button_container_4
			change_option()

	# Construction Menu
		5:
			current_page = page_5
			current_page_buttons = button_container_5

	# Selection Menu
		6:
			current_page = page_6
			icon_left.visible = false
			icon_right.visible = false
			if Global.current_game_mode == Global.GameMode.PLAY:
				player_mode.visible = true

	# Exit Menu
		7:
			current_page = page_7
			current_page_buttons = button_container_7

	current_page.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if page == 6:
		start_level_selection()
	else:
		_update_cursor_position()

	control_active = true

func _update_cursor_position() -> void:
	var target_button: Button = current_page_buttons[current_index]
	icon_left.global_position = target_button.global_position + Vector2(-12, (target_button.size.y / 2) - 2)
	icon_right.global_position = target_button.global_position + Vector2(target_button.size.x + 11, (target_button.size.y / 2) - 2)

#endregion

#region PAGE 6

func start_level_selection():
	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY]:
		level_select_list = scan_level_directory()
		page6_title.text = "FREEPLAY LEVELS:"
	elif Global.current_gameplay_mode == Global.GamePlay.CUSTOM:
		level_select_list = scan_level_directory(true)
		page6_title.text = "CUSTOM LEVELS:"
	elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		level_select_list = scan_level_directory()
		page6_title.text = "SURVIVAL LEVELS:"
	level_select_index = 0
	page6_error.modulate = Color(0.0, 0.0, 0.0, 0.0)
	_move_level_selection(0)

func scan_level_directory(custom: bool = false) -> Array:
	var levels = []
	var path: String
	var extension: String
	if custom:
		var dir_check = DirAccess.open("user://")
		if not dir_check.dir_exists("levels"):
			dir_check.make_dir("levels")
		path = "user://levels/"
		extension = ".bcd"
	else:
		path = "res://campaign_levels/"
		extension = ".json"

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(extension):
				levels.append(file_name.get_slice(".", 0))
			file_name = dir.get_next()

	levels.sort_custom(func(a, b):
		var num_a = int(a.substr(a.find("_") + 1))
		var num_b = int(b.substr(b.find("_") + 1))
		return num_a < num_b
	)

	return levels

func _update_level_label():
	if level_select_list.is_empty():
		level_name.text = "NO LEVELS TO LOAD"
		to_left.self_modulate = Color("4F4F4F")
		to_right.self_modulate = Color("4F4F4F")
		return

	var levelname: String = level_select_list[level_select_index].to_upper()
	levelname = levelname.replace("_", " ")
	if levelname.length() > 20:
		levelname = levelname.substr(0, 20)
	level_name.text = levelname
	if Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		page6_score.visible = true
		var msg = Global.get_translated_text("SCORE:")
		page6_score.text = msg + " " + Highscore.get_level_score(level_select_list[level_select_index])
	else:
		page6_score.visible = false

func _move_level_selection(direction: int):
	if level_select_list.size() <= 0:
		return

	var limit = level_select_list.size() - 1
	if Global.current_gameplay_mode in [Global.GamePlay.FREEPLAY, Global.GamePlay.SURVIVAL]:
		limit = Highscore.levels_unlocked - 1

	level_select_index += direction
	if level_select_index < 0:
		level_select_index = 0
	elif level_select_index > limit:
		level_select_index = limit
	page6_error.modulate = Color(0.0, 0.0, 0.0, 0.0)

	if level_select_index == 0:
		to_left.self_modulate = Color("4F4F4F")
	else:
		to_left.self_modulate = Color("FFF")

	if level_select_index == limit:
		to_right.self_modulate = Color("4F4F4F")
	else:
		to_right.self_modulate = Color("FFF")
	_update_level_label()

func _activate_level_selection():
	if level_select_list.is_empty():
		control_active = true
		SoundManager.play_sound("menu_blocked")
		return

	var levelname: String = level_select_list[level_select_index]

	if not validate_level_file(levelname):
		page6_error.modulate = Color(1.0, 1.0, 1.0, 1.0)
		SoundManager.play_sound("menu_blocked")
		return

	if Global.current_game_mode == Global.GameMode.PLAY:
		var level: int = 1
		if Global.freeplay_to_campaign:
			level = levelname.replace("level_", "").to_int()
		to_level_scene(Global.current_gameplay_mode, levelname, level)
	elif Global.current_game_mode == Global.GameMode.MAKER:
		to_maker_scene(levelname)

func get_filepath(path_name: String, system: bool = false) -> String:
	var dir_path: String
	var file_ext: String
	if system:
		dir_path = "res://campaign_levels/"
		file_ext = ".json"
	else:
		dir_path = "user://levels/"
		if not DirAccess.dir_exists_absolute(dir_path):
			var err = DirAccess.make_dir_recursive_absolute(dir_path)
			if err != OK:
				print("ERRO CRÍTICO: Não foi possível criar o diretório de save: ", dir_path)
		file_ext = ".bcd"
	return dir_path + path_name + file_ext

func validate_level_file(levelname: String) -> bool:
	var file_path: String

	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY, Global.GamePlay.SURVIVAL]:
		file_path = get_filepath(levelname, true)
	else:
		file_path = get_filepath(levelname) 

	if not FileAccess.file_exists(file_path):
		print("Arquivo de nível não encontrado: ", file_path)
		return false

	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, "battle_tank_maker")
	
	if not file:
		print("Erro ao abrir arquivo criptografado. Senha errada ou arquivo corrompido.")
		return false

	var content = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(content)
	if typeof(parse_result) == TYPE_NIL:
		print("Erro ao parsear JSON do nível: ", file_path)
		return false

	var all_level_data = parse_result as Dictionary

	if all_level_data.has("level_info"):
		var level_info = all_level_data["level_info"]
		
		if not level_info.has("level_name") or not level_info.has("total_bots") or\
		not level_info.has("spawn_speed") or not level_info.has("bot_list"):
			print("Estrutura de JSON inválida: ", file_path)
			return false
	else:
		print("Estrutura de JSON inválida: ", file_path)
		return false

	if not all_level_data.has("tile_data"):
		print("Estrutura de JSON inválida: ", file_path)
		return false

	print("Nível %s verificado com sucesso!" % levelname)
	return true

#endregion
