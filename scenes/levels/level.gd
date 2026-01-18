extends Node2D

# Gameplay
@onready var bonus_1: Area2D = $"Bonus 1"
@onready var bonus_2: Area2D = $"Bonus 2"
@onready var terrain: TileMapLayer = $Terrain
@onready var game_hud: Control = $"Game Hud"

@onready var protection_timer: Timer = $ProtectionTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var finish_timer: Timer = $FinishTimer
@onready var freeze_timer: Timer = $FreezeTimer
@onready var flickin_timer: Timer = $FlickinTimer

var flickin_times: int = 0
var flick_state: bool = false

@onready var level_camera: Camera2D = $LevelCamera
@onready var enemy_container: Node2D = $Bots
@onready var player_base: StaticBody2D = $"Player Base"

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var results_screen: CanvasLayer = $"Results Screen"

@onready var player_1: CharacterBody2D = $Player1
@onready var player_2: CharacterBody2D = $Player2
@onready var player_3: CharacterBody2D = $Player3
@onready var player_4: CharacterBody2D = $Player4

@onready var gameover_overlayer: ColorRect = $GameOverMessages/GameoverOverlayer
@onready var game_over_general: Sprite2D = $GameOverMessages/GameOver
@onready var game_over_p1: Sprite2D = $GameOverMessages/GameOverP1
@onready var game_over_p2: Sprite2D = $GameOverMessages/GameOverP2
@onready var game_over_p3: Sprite2D = $GameOverMessages/GameOverP3
@onready var game_over_p4: Sprite2D = $GameOverMessages/GameOverP4

@onready var anim_geral: AnimationPlayer = $GameOverMessages/AnimPlayerGeral
@onready var anim_p1: AnimationPlayer = $GameOverMessages/AnimPlayerP1
@onready var anim_p2: AnimationPlayer = $GameOverMessages/AnimPlayerP2
@onready var anim_p3: AnimationPlayer = $GameOverMessages/AnimPlayerP3
@onready var anim_p4: AnimationPlayer = $GameOverMessages/AnimPlayerP4

@onready var game_over_timer_p1: Timer = $GameOverMessages/GameOverTimerP1
@onready var game_over_timer_p2: Timer = $GameOverMessages/GameOverTimerP2
@onready var game_over_timer_p3: Timer = $GameOverMessages/GameOverTimerP3
@onready var game_over_timer_p4: Timer = $GameOverMessages/GameOverTimerP4

var spawn_points: Array = []
@export var spawn_point1: Vector2 = Vector2(72.0, 32.0)
@export var spawn_point2: Vector2 = Vector2(168.0, 32.0)
@export var spawn_point3: Vector2 = Vector2(264.0, 32.0)
@export var spawn_order: int = 1

var has_water_tiles: bool = false

var spawn_interval: float = 3.5
var max_active_enemies: int = 4
var total_bots_in_level: int = 20
var bot_number: int = 1

var game_over_stack: int = 0
var game_players: int = 1

var BOT_SCENE = preload("res://scenes/enemies/bot.tscn")
var frozen_spawn: bool = false

var spawn_queue: Array[Dictionary] = []
var active_enemies: Array[Node2D] = []

var base_area_position: String = "down"
var base_position: Dictionary = {
	"down": Vector2(168.0, 224.0),
	"up": Vector2(168.0, 32.0),
	"left": Vector2(72.0, 128.0),
	"right": Vector2(264.0, 128.0)
}
var base_exclusion_rects: Dictionary = {
	"down": Rect2i(19, 25, 4, 3),
	"up": Rect2i(19, 2, 4, 3),
	"left": Rect2i(8, 13, 3, 4),
	"right": Rect2i(31, 13, 3, 4)
}
var protection_area: Dictionary = {
	"down": [
		Vector2i(19,27), Vector2i(19,26), Vector2i(19,25), Vector2i(20,25),
		Vector2i(21,25), Vector2i(22,25), Vector2i(22,26), Vector2i(22,27),
	],
	"up": [
		Vector2i(19,2), Vector2i(19,3), Vector2i(19,4), Vector2i(20,4),
		Vector2i(21,4), Vector2i(22,4), Vector2i(22,3), Vector2i(22,2),
	],
	"left": [
		Vector2i(8,13), Vector2i(9,13), Vector2i(10,13), Vector2i(10,14),
		Vector2i(8,16), Vector2i(9,16), Vector2i(10,16), Vector2i(10,15),
	],
	"right": [
		Vector2i(31,13), Vector2i(32,13), Vector2i(33,13), Vector2i(31,14),
		Vector2i(31,16), Vector2i(32,16), Vector2i(33,16), Vector2i(31,15),
	],
}

var player_hitted: bool = false
var fixed_total_bots: int = 0

# Maker
var current_mode: int = 0
var level_number: int = 1
var level_name: String = ""
var bot_list: Array = []

func _ready() -> void:
	level_number = Global.current_level_number
	current_mode = Global.current_game_mode
	level_name = Global.current_level_name
	game_players = Global.current_level_players

	LoadingScreen.transition_finished.connect(_on_transition_finished)

	game_hud.players = game_players
	game_hud.toggle_hud_itens()

	var survival_round = ""
	if Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		var msg = Global.get_translated_text("ROUND")
		survival_round = "\n" + msg + " " + str(Global.current_level_round)

	pause_menu.visible = false
	results_screen.visible = false
	results_screen.create_data(get_formatted_level_name(), survival_round)
	results_screen.finish_results.connect(_finish_level)

	if current_mode == 0:
		if Global.current_gameplay_mode == Global.GamePlay.CAMPAIGN:
			load_level("level_" + str(level_number))
		elif Global.current_gameplay_mode in [Global.GamePlay.FREEPLAY, Global.GamePlay.CUSTOM]:
			load_level(level_name)
		elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
			load_level(level_name)
			Global.set_level_round_data()
		generate_base()
	else:
		goto_menu()

func get_formatted_level_name() -> String:
	var lvlnm = Global.current_level_name
	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY, Global.GamePlay.SURVIVAL]:
		if lvlnm.begins_with("level_"):
			var msg = Global.get_translated_text("LEVEL")
			var nmb = lvlnm.replace("level", "")
			return msg + nmb
	return lvlnm

func _on_transition_finished():
	start_level()

func start_level():
	pause_menu.in_transition = false
	define_level_difficulty()
	generate_players()
	if Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		populate_random_spawn_queue()
	else:
		populate_spawn_queue()
	try_spawn_bot()
	spawn_timer.start(spawn_interval)

func define_level_difficulty():
	if Global.current_gameplay_mode == Global.GamePlay.CAMPAIGN:
		campaign_config()
	elif Global.current_gameplay_mode == Global.GamePlay.FREEPLAY:
		if Global.freeplay_to_campaign:
			campaign_config()
	elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		survival_config()

func campaign_config():
	match game_players:
		1:
			max_active_enemies = 5
			spawn_interval -= 0.1
		2:
			max_active_enemies = 6
			spawn_interval -= 0.3
		3:
			max_active_enemies = 8
			spawn_interval -= 0.5
		4:
			max_active_enemies = 10
			spawn_interval -= 0.7

	if Global.hard_mode:
		max_active_enemies += 2
		spawn_interval /= 2

func survival_config():
	Global.current_level_round += 1
	var values: Dictionary = Global.level_round_data
	spawn_interval -= values.get("time", 0.2)
	total_bots_in_level = values.get("bots", 10)
	max_active_enemies = values.get("active", 4)

#region Players Generation

func generate_players():
	if game_players >= 1:
		if player_1 != null:
			player_1.generate_player()
	if game_players >= 2:
		if player_2 != null:
			player_2.generate_player()
	if game_players >= 3:
		if player_3 != null:
			player_3.generate_player()
	if game_players >= 4:
		if player_4 != null:
			player_4.generate_player()

func player_game_over(player: int):
	if Global.in_game_over: return
	match player:
		1:
			anim_p1.play("game_over")
			game_over_p1.visible = true
			game_over_timer_p1.start()
			game_over_stack += 1
		2:
			anim_p2.play("game_over")
			game_over_p2.visible = true
			game_over_timer_p2.start()
			game_over_stack += 1
		3:
			anim_p3.play("game_over")
			game_over_p3.visible = true
			game_over_timer_p3.start()
			game_over_stack += 1
		4:
			anim_p4.play("game_over")
			game_over_p4.visible = true
			game_over_timer_p4.start()
			game_over_stack += 1

	if game_over_stack >= game_players:
		reset_game_over_message()
		if Global.total_revives > 0:
			Global.decrease_revives()
			SoundManager.play_sound("revive_players")
			generate_players()
			for j in range(game_players):
				Global.add_lifes(j + 1, false)
		else:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(gameover_overlayer, "self_modulate", Color(1, 1, 1, 1), 1.2)
			game_over_general.visible = true
			Global.in_game_over = true
			player_base.is_invencible = true
			anim_geral.play("game_over")
			level_game_over()

func reset_game_over_message():
	game_over_p1.visible = false
	game_over_p2.visible = false
	game_over_p3.visible = false
	game_over_p4.visible = false

#endregion

#region Base Generation

func generate_base():
	_clear_tiles_at_rect(base_exclusion_rects[base_area_position])
	basic_protection(true, Vector2i(0,0))
	var base_pos = base_position.get(base_area_position, "down")
	player_base.active_base(base_pos, base_area_position)

func base_destroyed():
	if Global.in_game_over: return
	Global.in_game_over = true
	reset_game_over_message()
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(gameover_overlayer, "self_modulate", Color(1, 1, 1, 1), 1.2)
	game_over_general.visible = true
	anim_geral.play("game_over")
	level_game_over()

func _clear_tiles_at_rect(tile_rect: Rect2i) -> void:
	for y in range(tile_rect.position.y, tile_rect.end.y):
		for x in range(tile_rect.position.x, tile_rect.end.x):
			terrain.set_cell(Vector2i(x, y), -1)

#endregion

#region Bot Generation

func populate_spawn_queue():
	spawn_queue.clear()

	if bot_list.is_empty():
		bot_list = generate_default_list()

	var total = min(bot_list.size(), total_bots_in_level)
	var bot_index = 1

	for i in range(total):
		var bot_type = bot_list[i]
		var is_special = (bot_index == 4) or (bot_index > 4 and (bot_index - 4) % 7 == 0)
		spawn_queue.append({"state": bot_type, "special": is_special, "reinforcement": false})
		bot_index += 1

	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY]:
		if Global.hard_mode:
			var extra = 10
			if game_players > 2:
				extra = 20
			for i in range(extra):
				var random_type = randi_range(1, 4)
				var is_special = i == 5 or i == 15
				spawn_queue.append({"state": random_type, "special": is_special, "reinforcement": true})
				total_bots_in_level += 1

	Global.set_level_bots(total_bots_in_level)
	fixed_total_bots = Global.level_bots

func populate_random_spawn_queue():
	spawn_queue.clear()

	bot_list = []
	bot_list = generate_default_list(true)

	var total = total_bots_in_level
	var bot_index = 1

	for i in range(total):
		var bot_type = bot_list[i]
		var is_special = (bot_index == 4) or (bot_index > 4 and (bot_index - 4) % 7 == 0)
		spawn_queue.append({"state": bot_type, "special": is_special, "reinforcement": false})
		bot_index += 1

	var data: Dictionary = Global.level_round_data
	var extra = data.get("extra", 0)
	for i in range(extra):
		var random_type = randi_range(1, data.get("type", 1))
		var is_special = i == 5 or i == 15
		spawn_queue.append({"state": random_type, "special": is_special, "reinforcement": true})
		total_bots_in_level += 1

	Global.set_level_bots(total_bots_in_level)
	fixed_total_bots = Global.level_bots

func try_spawn_bot():
	if active_enemies.size() >= max_active_enemies:
		return

	if spawn_queue.is_empty():
		spawn_timer.stop()
		check_level_win_condition()
		return

	# Generate Bots
	var bot_data: Dictionary = spawn_queue.pop_front()

	var new_bot = BOT_SCENE.instantiate()
	new_bot.bot_hit.connect(_on_bot_hit.bind(new_bot))
	new_bot.bot_died.connect(_on_bot_died.bind(new_bot))
	new_bot.name = "Bot " + str(bot_number)
	bot_number += 1

	new_bot.global_position = spawn_points.get(spawn_order)
	if spawn_order < 2:
		spawn_order += 1
	else:
		spawn_order = 0

	enemy_container.add_child(new_bot)
	active_enemies.append(new_bot)

	# Recurso original desativado 
	#if bot_data["special"] and bonus_1.is_active:
		#despawn_powerup()

	new_bot.generate_bot(bot_data["state"], bot_data["special"], bot_data["reinforcement"])
	Global.decrease_level_bots()
	new_bot.is_frozen = frozen_spawn

func freeze_bots(freeze: bool = true, freeze_players: bool = false):
	if freeze_players:
		player_1.is_freeze()
		player_2.is_freeze()
		player_3.is_freeze()
		player_4.is_freeze()
	else:
		frozen_spawn = freeze
		for bot in active_enemies:
			bot.is_frozen = freeze
		if freeze:
			freeze_timer.start(10.0)

func _on_freeze_timeout() -> void:
	if frozen_spawn:
		freeze_bots(false, false)

func kill_active_bots(kill_players: bool = false):
	if kill_players:
		if not player_1.operating and not player_2.operating and not player_3.operating and not player_4.operating:
			return

		SoundManager.play_sound("player_hitted")
		level_camera.start_shake(2.0, 0.4)
		player_1.hitted_by_granade = true
		player_2.hitted_by_granade = true
		player_3.hitted_by_granade = true
		player_4.hitted_by_granade = true
		player_1.receive_hit(true)
		player_2.receive_hit(true)
		player_3.receive_hit(true)
		player_4.receive_hit(true)

	else:
		var bot_arr:Array = enemy_container.get_children()
		if bot_arr.is_empty():
			return

		SoundManager.play_sound("enemy_hitted")
		level_camera.start_shake(2.0, 0.4)
		for bot in bot_arr:
			if bot.is_in_group("Enemies") or bot.is_in_group("EnemiesDisabled"):
				bot.hitted_by_granade = true
				bot.receive_hit(-1)

func upgrade_active_bots():
	var bot_arr:Array = enemy_container.get_children()
	if bot_arr.is_empty():
		return
	for bot in bot_arr:
		if bot.is_in_group("Enemies") or bot.is_in_group("EnemiesDisabled"):
			bot.upgrade_armor()

func arms_active_bots():
	var bot_arr:Array = enemy_container.get_children()
	if bot_arr.is_empty():
		return
	for bot in bot_arr:
		if bot.is_in_group("Enemies") or bot.is_in_group("EnemiesDisabled"):
			bot.add_star()

func protect_active_bots():
	var bot_arr:Array = enemy_container.get_children()
	if bot_arr.is_empty():
		return
	for bot in bot_arr:
		if bot.is_in_group("Enemies") or bot.is_in_group("EnemiesDisabled"):
			bot.gain_life()

func _on_bot_hit(bot_node: Node2D):
	if bot_node.is_special and not bot_node.hitted_by_granade:
		spawn_powerup()
		bot_node.disable_special_mode()

func _on_bot_died(bot_node: Node2D):
	results_screen.increment_bot_list(bot_node.player_who_hit, bot_node.bot_state)
	active_enemies.erase(bot_node)
	check_level_win_condition()

func _on_spawn_timeout() -> void:
	try_spawn_bot()

#endregion

#region Power Up
func spawn_powerup():
	bonus_1.generate_powerup()
	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY]:
		if Global.hard_mode:
			bonus_2.generate_powerup()
	else:
		if Global.current_level_round >= 20:
			bonus_2.generate_powerup()

func despawn_powerup():
	bonus_1.despawn_powerup(0)
	bonus_2.despawn_powerup(0)

#endregion

#region Shovel Action
func protect_eagle(disable_shield: bool = false):
	flickin_timer.stop()
	flickin_times = 0
	flick_state = false

	if disable_shield:
		protection_timer.start(15.0)
		basic_protection(false, Vector2i(0,0))
	else:
		protection_timer.start(15.0)
		basic_protection(true, Vector2i(0,1))

func basic_protection(active: bool, type: Vector2i):
	var cur_area = protection_area.get(base_area_position, "down")
	if active:
		for block in cur_area:
			terrain.set_cell(block, 1, type)
	else:
		for block in cur_area:
			terrain.set_cell(block, -1)

func on_protection_timeout():
	flickin_timer.start()

func _on_flickin_timeout():
	if flickin_timer.is_stopped(): return
	if flickin_times < 12:
		if flick_state:
			flick_state = false
			basic_protection(true, Vector2i(0,0))
		else:
			flick_state = true
			basic_protection(true, Vector2i(0,1))
		flickin_times += 1
	else:
		flickin_timer.stop()
		flickin_times = 0
		flick_state = false

#endregion

#region Load Area

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

func get_tile_data_for_saving() -> Array:
	var tile_data_to_save = []
	var used_cells = terrain.get_used_cells()
	
	for cell_pos in used_cells:
		var source_id = terrain.get_cell_source_id(cell_pos)
		var atlas_coords = terrain.get_cell_atlas_coords(cell_pos)
		
		tile_data_to_save.append({
			"pos_x": cell_pos.x,
			"pos_y": cell_pos.y,
			"source_id": source_id,
			"atlas_x": atlas_coords.x,
			"atlas_y": atlas_coords.y
		})
	return tile_data_to_save

func load_level(levelname: String) -> bool:
	var file_path: String

	if Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY, Global.GamePlay.SURVIVAL]:
		file_path = get_filepath(levelname, true)
	else:
		file_path = get_filepath(levelname)

	if not FileAccess.file_exists(file_path):
		return false

	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, "battle_tank_maker")
	
	if not file:
		return false
		
	var content = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(content)
	if typeof(parse_result) == TYPE_NIL:
		return false

	var all_level_data = parse_result as Dictionary

	if all_level_data.has("level_info"):
		var level_info = all_level_data["level_info"]
		level_name = level_info.get("level_name", "level_1")
		total_bots_in_level = level_info.get("total_bots", 20)
		spawn_interval = level_info.get("spawn_speed", 2.5)
		bot_list = level_info.get("bot_list", generate_default_list())
	else:
		total_bots_in_level = 20
		spawn_interval = 2.5
		bot_list = generate_default_list()

	if all_level_data.has("tile_data"):
		var tile_data_array = all_level_data["tile_data"]
		terrain.clear()
		
		for tile_data in tile_data_array:
			var pos = Vector2i(tile_data["pos_x"], tile_data["pos_y"])
			var source_id = tile_data["source_id"]
			var atlas_coords = Vector2i(tile_data["atlas_x"], tile_data["atlas_y"])
			terrain.set_cell(pos, source_id, atlas_coords)

	if all_level_data.has("spawns_info"):
		var spawns_info = all_level_data["spawns_info"]
		base_area_position = spawns_info.get("base_position", "down")
		var top_left_pos: Vector2
		var tile_pos: Vector2i
		var spawn_rect: Rect2i

		var p1_pos = spawns_info.get("player_1", player_1.spawn_position)
		if p1_pos:
			player_1.spawn_position = Vector2(p1_pos[0], p1_pos[1])
			top_left_pos = player_1.spawn_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var p2_pos = spawns_info.get("player_2", player_2.spawn_position)
		if p2_pos:
			player_2.spawn_position = Vector2(p2_pos[0], p2_pos[1])
			if Global.current_level_players >= 2:
				top_left_pos = player_2.spawn_position - Vector2(8, 8)
				tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
				spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
				_clear_tiles_at_rect(spawn_rect)

		var p3_pos = spawns_info.get("player_3", player_3.spawn_position)
		if p3_pos:
			player_3.spawn_position = Vector2(p3_pos[0], p3_pos[1])
			if Global.current_level_players >= 3:
				top_left_pos = player_3.spawn_position - Vector2(8, 8)
				tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
				spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
				_clear_tiles_at_rect(spawn_rect)

		var p4_pos = spawns_info.get("player_4", player_4.spawn_position)
		if p4_pos:
			player_4.spawn_position = Vector2(p4_pos[0], p4_pos[1])
			if Global.current_level_players >= 4:
				top_left_pos = player_4.spawn_position - Vector2(8, 8)
				tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
				spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
				_clear_tiles_at_rect(spawn_rect)

		var b1_pos = spawns_info.get("bot_1", spawn_point1)
		if b1_pos:
			spawn_point1 = Vector2(b1_pos[0], b1_pos[1])
			top_left_pos = spawn_point1 - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var b2_pos = spawns_info.get("bot_2", spawn_point2)
		if b2_pos:
			spawn_point2 = Vector2(b2_pos[0], b2_pos[1])
			top_left_pos = spawn_point2 - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var b3_pos = spawns_info.get("bot_3", spawn_point3)
		if b3_pos:
			spawn_point3 = Vector2(b3_pos[0], b3_pos[1])
			top_left_pos = spawn_point3 - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

	else:
		base_area_position = "down"
	
	spawn_points = [spawn_point1, spawn_point2, spawn_point3]
	check_if_level_has_water()
	return true

func check_if_level_has_water() -> void:
	has_water_tiles = false
	var used_cells := terrain.get_used_cells()
	for cell_pos in used_cells:
		var tile_data := terrain.get_cell_tile_data(cell_pos)
		if tile_data:
			var tile_type = tile_data.get_custom_data("Type")
			if tile_type == "water":
				has_water_tiles = true
				return

func goto_menu():
	LoadingScreen.play_transition_to_scene("res://scenes/menu/main_menu.tscn", "")

#endregion

func generate_default_list(random: bool = false) -> Array:
	var list: Array = []
	var val = 1
	for i in range(100):
		if random:
			val = randi_range(1, 4)
		list.append(val)
	return list

func check_level_win_condition():
	if Global.in_game_over: return
	if spawn_queue.is_empty() and active_enemies.is_empty():
		player_base.is_invencible = true
		finish_timer.start()

func level_game_over():
	pause_menu.in_transition = true
	SoundManager.in_game_over = true
	finish_timer.start()

func _on_finish_level_timeout() -> void:
	results_screen.start_transition()
	pause_menu.in_transition = true
	if bonus_1.is_active or bonus_2.is_active:
		despawn_powerup()
	player_1.disable_actions()
	player_2.disable_actions()
	player_3.disable_actions()
	player_4.disable_actions()

func _finish_level() -> void:
	if Global.in_game_over:
		if Global.current_gameplay_mode == Global.GamePlay.CAMPAIGN:
			Global.check_and_update_highscore()
			Highscore.save_highscores()
		elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
			Highscore.save_level_score(level_name, Global.general_score)
		goto_menu()

	else:
		if Global.current_gameplay_mode == Global.GamePlay.CAMPAIGN:
			Global.check_and_update_highscore()
			Global.current_level_number += 1
			if Global.current_level_number > 100:
				Global.current_level_number = 1
			Global.current_level_name = "level_" + str(Global.current_level_number)
			Global.set_level(Global.current_level_number)
			Highscore.new_levels_unlocked(Global.current_level_number)
			LoadingScreen.play_transition_to_scene("res://scenes/levels/level.tscn", get_formatted_level_name(), true)

		elif Global.current_gameplay_mode == Global.GamePlay.FREEPLAY:
			if Global.freeplay_to_campaign:
				Global.current_level_number += 1
				if Global.current_level_number > 100:
					Global.current_level_number = 1
				Global.current_level_name = "level_" + str(Global.current_level_number)
				Global.set_level(Global.current_level_number)
				LoadingScreen.play_transition_to_scene("res://scenes/levels/level.tscn", get_formatted_level_name(), true)
			else:
				MenuState.skip_intro = true
				MenuState.start_in = 3
				goto_menu()

		elif Global.current_gameplay_mode == Global.GamePlay.CUSTOM:
			MenuState.skip_intro = true
			MenuState.start_in = 3
			goto_menu()
		
		elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
			Global.check_and_update_highscore()
			var msg = Global.get_translated_text("ROUND")
			var survival_round = "\n" + msg + " " + str(Global.current_level_round)
			LoadingScreen.play_transition_to_scene("res://scenes/levels/level.tscn", get_formatted_level_name(), true, survival_round)

		else:
			goto_menu()

func _on_level_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		area.queue_free()

func _on_level_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players") or body.is_in_group("PlayersDisabled"):
		if body.operating:
			body.receive_hit(true)
	if body.is_in_group("Enemies") or body.is_in_group("EnemiesDisabled"):
		body.receive_hit(-1)

func _on_game_over_p1_timeout() -> void:
	anim_p1.play("RESET")

func _on_game_over_p2_timeout() -> void:
	anim_p2.play("RESET")

func _on_game_over_p3_timeout() -> void:
	anim_p3.play("RESET")

func _on_game_over_p4_timeout() -> void:
	anim_p4.play("RESET")
