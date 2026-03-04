# maker.gd
extends Node2D

enum MakerMode { TILE, BASE, SPAWNER }
var current_maker_mode: MakerMode = MakerMode.TILE

enum TileAction { BUILD, ERASE }
var current_tile_action: TileAction = TileAction.BUILD

# Gameplay
@onready var terrain: TileMapLayer = $Terrain
@onready var barrier: TileMapLayer = $Barrier
@onready var player_base: StaticBody2D = $"Player Base"

@onready var export_file_dialog: FileDialog = $ExportFileDialog

var spawn_interval: float = 2.5
var total_bots_in_level: int = 20

var confirmed_exit: bool = false

var base_area_position: String = "down"
var old_base_area_position: String = "down"

# HUD
@onready var option_selected: Sprite2D = $HUD/OptionSelected
@onready var tile_block_icon: AnimatedSprite2D = $HUD/TileBlock
@onready var player_base_icon: AnimatedSprite2D = $HUD/PlayerBase
@onready var select_spawns: Sprite2D = $HUD/SelectSpawns
@onready var bot_spawn_1_icon: Sprite2D = $HUD/HudBot/BotSpawn1
@onready var bot_spawn_2_icon: Sprite2D = $HUD/HudBot/BotSpawn2
@onready var bot_spawn_3_icon: Sprite2D = $HUD/HudBot/BotSpawn3
@onready var player_spawn_1_icon: Sprite2D = $HUD/HudPlayers/PlayerSpawn1
@onready var player_spawn_2_icon: Sprite2D = $HUD/HudPlayers/PlayerSpawn2
@onready var player_spawn_3_icon: Sprite2D = $HUD/HudPlayers/PlayerSpawn3
@onready var player_spawn_4_icon: Sprite2D = $HUD/HudPlayers/PlayerSpawn4

# Maker
@onready var maker_cursor: AnimatedSprite2D = $"Maker Cursor"

@onready var save_level_window: PanelContainer = $"Save Level Window"
@onready var level_saved_message: Control = $"Level Saved Message"
@onready var exit_panel: PanelContainer = $ExitPanel

@onready var save_message_timer: Timer = $SaveMessageTimer

@onready var spawn_p1: Sprite2D = $PlayerSpawn/SpawnP1
@onready var spawn_p2: Sprite2D = $PlayerSpawn/SpawnP2
@onready var spawn_p3: Sprite2D = $PlayerSpawn/SpawnP3
@onready var spawn_p4: Sprite2D = $PlayerSpawn/SpawnP4
@onready var bot_spawn1: Sprite2D = $BotSpawn/BotSpawn1
@onready var bot_spawn2: Sprite2D = $BotSpawn/BotSpawn2
@onready var bot_spawn3: Sprite2D = $BotSpawn/BotSpawn3

var pending_export_data: Dictionary
var pending_export_levelname: String

var all_spawn_sprites: Array[Sprite2D] = []

var current_item_selected: Node2D = null
var movable_spawn_player: int = 1
var movable_spawn_bot: int = 1

var pointer_pos: Vector2 = Vector2.ZERO
var pointer_down: bool = false
var pointer_just_pressed: bool = false

var currently_dragged_spawn: Sprite2D = null
var drag_start_position: Vector2 = Vector2.ZERO

var in_popup: bool = false

var current_mode: int = 0
var level_number: int = 1
var level_name: String = ""
var bot_list: Array = []

var base_spawn: int = 1
var bot_spawn: Array = []
var player_spawn: Array = []

var available_maker_tiles: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0),
	Vector2i(0,1), Vector2i(2,1),
	Vector2i(0,2), Vector2i(2,2), Vector2i(4,2)
]

var current_tile_index: int = 0
var tile_source_id: int = 1

const MAKER_BOUNDARY = Rect2i(8, 2, 26, 26)
var exclusion_zones: Array[Rect2i] = []

func _ready() -> void:
	if Global.os_type == "desktop":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		maker_cursor.visible = false

	set_tile_action(true)
	MobileControl.control_mode("build1")
	MobileControl.change_sprite_buttons("save")

	tile_block_icon.get_child(0).pressed.connect(_on_hud_icon_pressed.bind(tile_block_icon, MakerMode.TILE))
	player_base_icon.get_child(0).pressed.connect(_on_hud_icon_pressed.bind(player_base_icon, MakerMode.BASE))
	select_spawns.get_child(0).pressed.connect(_on_hud_icon_pressed.bind(select_spawns, MakerMode.SPAWNER))
	current_item_selected = tile_block_icon
	option_selected.global_position = current_item_selected.global_position

	exclusion_zones.append(player_base.base_exclusion_rects[base_area_position])

	level_number = Global.current_level_number
	current_mode = Global.current_game_mode
	level_name = Global.current_level_name

	all_spawn_sprites = [
		spawn_p1, spawn_p2, spawn_p3, spawn_p4,
		bot_spawn1, bot_spawn2, bot_spawn3
	]

	save_level_window.save_cancelled.connect(_on_save_cancelled)
	save_level_window.save_confirmed.connect(_on_save_confirmed)
	save_level_window.export_requested.connect(_on_export_requested)

	terrain.clear()
	if current_mode == 1:
		load_level(level_name)
		generate_base()
	else:
		goto_menu()

func _process(_delta: float) -> void:
	if current_mode == 1 and not in_popup:
		if not confirmed_exit:
			match current_maker_mode:
				MakerMode.TILE:
					_handle_tile_input()
				MakerMode.BASE:
					_handle_base_input()
				MakerMode.SPAWNER:
					_handle_spawn_input()

		# Salvar
		if Input.is_action_just_pressed("menu_accept") or Input.is_action_just_pressed("game1_pause"):
			if confirmed_exit:
				back_editor()
			else:
				save_level_window.show_popup(level_name, total_bots_in_level, spawn_interval, bot_list)
				in_popup = true
				MobileControl.control_mode("hidden")

		# Sair
		if Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("game1_exit"):
			if confirmed_exit:
				exit_game()
			else:
				try_exit()

	if Global.os_type == "mobile":
		pointer_just_pressed = false

func _input(event):
	if event is InputEventScreenTouch:
		pointer_pos = event.position
		pointer_down = event.pressed
		pointer_just_pressed = event.pressed

	elif event is InputEventScreenDrag:
		pointer_pos = event.position
		pointer_down = true

func _handle_tile_input():
	if Global.os_type == "mobile":
		maker_cursor.visible = false

		# Change Tile
		if Input.is_action_just_pressed("menu_right") or Input.is_action_just_pressed("game1_right"):
			current_tile_index = (current_tile_index + 1) % available_maker_tiles.size()
			#get_viewport().set_input_as_handled()

		if Input.is_action_just_pressed("menu_left") or Input.is_action_just_pressed("game1_left"):
			current_tile_index = (current_tile_index - 1 + available_maker_tiles.size()) % available_maker_tiles.size()
			#get_viewport().set_input_as_handled()

		# Mobile Tile Action
		if Input.is_action_just_pressed("game_change_build"):
			var is_build = current_tile_action == TileAction.ERASE
			set_tile_action(is_build)

		var mouse_pos_local = terrain.to_local(pointer_pos)
		var map_coords = terrain.local_to_map(mouse_pos_local)
		tile_block_icon.change_sprite(current_tile_index)

		# Touch Pressed
		if pointer_down:
			if not is_valid_drawing_location(map_coords):
				return

			match current_tile_action:
				TileAction.BUILD:
					var selected_tile_coords = available_maker_tiles[current_tile_index]
					terrain.set_cell(map_coords, tile_source_id, selected_tile_coords)
				TileAction.ERASE:
					terrain.set_cell(map_coords, -1)
			#get_viewport().set_input_as_handled()

		# Touch Just Pressed
		if pointer_just_pressed:
			if not is_valid_short_location(map_coords):
				SoundManager.play_sound("editor_error")
				return

	else:
		maker_cursor.visible = true
		var mouse_pos = get_global_mouse_position()
		var map_coords = terrain.local_to_map(terrain.to_local(mouse_pos))
		maker_cursor.global_position = terrain.to_global(terrain.map_to_local(map_coords))

		if is_valid_drawing_location(map_coords):
			maker_cursor.change_sprite(current_tile_index)
		else:
			maker_cursor.change_sprite(-1)
		tile_block_icon.change_sprite(current_tile_index)
		# Mouse Pressed
		if Input.is_action_pressed("game_build"):
			if is_valid_drawing_location(map_coords):
				var selected_tile_coords = available_maker_tiles[current_tile_index]
				terrain.set_cell(map_coords, tile_source_id, selected_tile_coords)
				get_viewport().set_input_as_handled()

		elif Input.is_action_pressed("game_destroy"):
			if is_valid_drawing_location(map_coords):
				maker_cursor.visible = false
				terrain.set_cell(map_coords, -1)
				get_viewport().set_input_as_handled()

		# Mouse Just Pressed
		if Input.is_action_just_pressed("game_build"):
			if not is_valid_short_location(map_coords):
				SoundManager.play_sound("editor_error")
				return

		elif Input.is_action_just_pressed("game_destroy"):
			if not is_valid_short_location(map_coords):
				SoundManager.play_sound("editor_error")
				return

		# Change Tile
		if Input.is_action_just_pressed("menu_right") or Input.is_action_just_pressed("game1_right"):
			current_tile_index = (current_tile_index + 1) % available_maker_tiles.size()
			get_viewport().set_input_as_handled()

		if Input.is_action_just_pressed("menu_left") or Input.is_action_just_pressed("game1_left"):
			current_tile_index = (current_tile_index - 1 + available_maker_tiles.size()) % available_maker_tiles.size()
			get_viewport().set_input_as_handled()

func _handle_base_input():
	maker_cursor.visible = false
	var target_position_key = ""

	if Input.is_action_just_pressed("menu_left") or Input.is_action_just_pressed("game1_left"):
		target_position_key = "left"
	elif Input.is_action_just_pressed("menu_right") or Input.is_action_just_pressed("game1_right"):
		target_position_key = "right"
	elif Input.is_action_just_pressed("menu_up") or Input.is_action_just_pressed("game1_up"):
		target_position_key = "up"
	elif Input.is_action_just_pressed("menu_down") or Input.is_action_just_pressed("game1_down"):
		target_position_key = "down"

	if target_position_key != "":
		if target_position_key != base_area_position:
			if _is_valid_base_location(target_position_key):
				base_area_position = target_position_key
				generate_base()
				get_viewport().set_input_as_handled()
			else:
				SoundManager.play_sound("editor_error")
				get_viewport().set_input_as_handled()
		else:
			get_viewport().set_input_as_handled()

func _handle_spawn_input() -> void:
	maker_cursor.visible = false
	if Global.os_type == "mobile":
		var snapped_mouse_pos = _get_snapped_pointer_pos()
		if pointer_down and not currently_dragged_spawn:
			if currently_dragged_spawn:
				return
			var mouse_pos = pointer_pos
			for spawn_sprite in all_spawn_sprites:
				var sprite_size = spawn_sprite.texture.get_size() * spawn_sprite.global_scale
				var top_left = spawn_sprite.global_position - (sprite_size / 2)
				var spawn_rect = Rect2(top_left, sprite_size)
				if spawn_rect.has_point(mouse_pos):
					currently_dragged_spawn = spawn_sprite
					drag_start_position = currently_dragged_spawn.global_position
					currently_dragged_spawn.modulate.a = 0.5
					# get_viewport().set_input_as_handled() # Remova isso do _process/handler
					break

		elif pointer_down and currently_dragged_spawn:
			currently_dragged_spawn.global_position = _get_snapped_pointer_pos()
			get_viewport().set_input_as_handled()

		elif not pointer_down and currently_dragged_spawn:
			var new_pos_snapped = snapped_mouse_pos
			if _is_valid_spawn_location(new_pos_snapped, currently_dragged_spawn):
				var top_left_pos = new_pos_snapped - Vector2(8, 8)
				var tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
				var spawn_tile_rect = Rect2i(tile_pos, Vector2i(2, 2))
				_clear_tiles_at_rect(spawn_tile_rect)
				currently_dragged_spawn.global_position = new_pos_snapped
			else:
				currently_dragged_spawn.global_position = drag_start_position
				SoundManager.play_sound("editor_error")
			currently_dragged_spawn.modulate.a = 1.0 
			currently_dragged_spawn = null
			drag_start_position = Vector2.ZERO
			#get_viewport().set_input_as_handled()

	else:
		var snapped_mouse_pos = _get_snapped_mouse_pos()
		if Input.is_action_just_pressed("game_build"):
			if currently_dragged_spawn:
				return
			var mouse_pos = get_global_mouse_position()
			for spawn_sprite in all_spawn_sprites:
				var mouse_local_pos = spawn_sprite.to_local(mouse_pos)
				if spawn_sprite.get_rect().has_point(mouse_local_pos):
					currently_dragged_spawn = spawn_sprite
					drag_start_position = currently_dragged_spawn.global_position
					currently_dragged_spawn.modulate.a = 0.5
					get_viewport().set_input_as_handled()
					break

		elif Input.is_action_pressed("game_build") and currently_dragged_spawn:
			currently_dragged_spawn.global_position = snapped_mouse_pos
			get_viewport().set_input_as_handled()

		elif Input.is_action_just_released("game_build") and currently_dragged_spawn:
			var new_pos_snapped = snapped_mouse_pos
			if _is_valid_spawn_location(new_pos_snapped, currently_dragged_spawn):
				var top_left_pos = new_pos_snapped - Vector2(8, 8)
				var tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
				var spawn_tile_rect = Rect2i(tile_pos, Vector2i(2, 2))
				_clear_tiles_at_rect(spawn_tile_rect)
				currently_dragged_spawn.global_position = new_pos_snapped
			else:
				currently_dragged_spawn.global_position = drag_start_position
				SoundManager.play_sound("editor_error")
			currently_dragged_spawn.modulate.a = 1.0 
			currently_dragged_spawn = null
			drag_start_position = Vector2.ZERO
			get_viewport().set_input_as_handled()

func set_tile_action(build: bool) -> void:
	current_tile_action = TileAction.BUILD if build else TileAction.ERASE
	if build:
		MobileControl.change_sprite_buttons("pencil")
	else:
		MobileControl.change_sprite_buttons("eraser")

func try_exit():
	if Global.os_type == "desktop":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	exit_panel.visible = true
	confirmed_exit = true
	MobileControl.control_mode("build3")
	MobileControl.change_sprite_buttons("okay")

func back_editor():
	if Global.os_type == "desktop":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	exit_panel.visible = false
	confirmed_exit = false
	MobileControl.change_sprite_buttons("save")
	mobile_layout()

func exit_game():
	MenuState.skip_intro = true
	MenuState.start_in = 5
	goto_menu()

func _get_snapped_pointer_pos() -> Vector2:
	return get_snapped_position(pointer_pos, 8)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not confirmed_exit and not in_popup:
			try_exit()

#region Base Generation

func generate_base():
	if old_base_area_position != base_area_position:
		var old_area = player_base.protection_area.get(old_base_area_position, "down")
		for block in old_area:
			if terrain.get_cell_atlas_coords(block) == Vector2i(0,0):
				terrain.set_cell(block, -1)

		var old_rect = player_base.base_exclusion_rects[old_base_area_position]
		var index = exclusion_zones.find(old_rect)
		if index != -1:
			exclusion_zones.remove_at(index)
			
		var new_rect = player_base.base_exclusion_rects[base_area_position]
		if not exclusion_zones.has(new_rect):
			exclusion_zones.append(new_rect)
			
		old_base_area_position = base_area_position

	_clear_tiles_at_rect(player_base.base_exclusion_rects[base_area_position])

	var cur_area = player_base.protection_area.get(base_area_position, "down")
	for block in cur_area:
		terrain.set_cell(block, 1, Vector2i(0,0))

	var base_pos = player_base.base_position.get(base_area_position, "down")
	player_base.active_base(base_pos, base_area_position)

func _clear_tiles_at_rect(tile_rect: Rect2i) -> void:
	for y in range(tile_rect.position.y, tile_rect.end.y):
		for x in range(tile_rect.position.x, tile_rect.end.x):
			terrain.set_cell(Vector2i(x, y), -1)

func is_valid_drawing_location(map_coords: Vector2i) -> bool:
	# Margin
	if not MAKER_BOUNDARY.has_point(map_coords):
		return false
	if not is_valid_short_location(map_coords):
		return false
	# Free
	return true

func is_valid_short_location(map_coords: Vector2i) -> bool:
	# Spawns
	for zone in exclusion_zones:
		if zone.has_point(map_coords):
			return false
	# Barrier
	var source_id = barrier.get_cell_source_id(map_coords)
	if source_id != -1:
		return false
	# Free
	return true

func _is_valid_base_location(new_position_key: String) -> bool:
	var proposed_base_rect = player_base.base_exclusion_rects[new_position_key]

	for spawn_sprite in all_spawn_sprites:
		var spawn_top_left = spawn_sprite.global_position - Vector2(8, 8)
		var spawn_tile_pos = terrain.local_to_map(terrain.to_local(spawn_top_left))
		var spawn_rect = Rect2i(spawn_tile_pos, Vector2i(2, 2))

		if proposed_base_rect.intersects(spawn_rect):
			return false

	return true

#endregion

#region Maker Mode

func get_filepath(path_name: String) -> String:
	var dir_path = "user://levels/"
	if not DirAccess.dir_exists_absolute(dir_path):
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			print("ERRO CRÍTICO: Não foi possível criar o diretório de save: ", dir_path)
	return dir_path + path_name + ".bcd"

func _on_save_cancelled():
	in_popup = false
	save_level_window.hide()
	mobile_layout()

func _on_save_confirmed(popup_data: Dictionary, levelname: String):
	save_level_window.hide()
	save_level(popup_data, levelname)

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

func save_level(popup_data: Dictionary, levelname: String):
	var file_path = get_filepath(levelname)
	var final_level_data = _build_level_data_dictionary(popup_data)
	var json_string = JSON.stringify(final_level_data, "\t")
	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, "battle_tank_maker")
	if file:
		file.store_string(json_string)
		file.close()
		level_saved_message.show()
		save_message_timer.start()

func load_level(levelname: String) -> bool:
	if levelname.is_empty():
		return false

	var file_path: String

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

		var p1_pos = spawns_info.get("player_1", spawn_p1.global_position)
		if p1_pos:
			spawn_p1.global_position = Vector2(p1_pos[0], p1_pos[1])
			top_left_pos = spawn_p1.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var p2_pos = spawns_info.get("player_2", spawn_p2.global_position)
		if p2_pos:
			spawn_p2.global_position = Vector2(p2_pos[0], p2_pos[1])
			top_left_pos = spawn_p2.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var p3_pos = spawns_info.get("player_3", spawn_p3.global_position)
		if p3_pos:
			spawn_p3.global_position = Vector2(p3_pos[0], p3_pos[1])
			top_left_pos = spawn_p3.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var p4_pos = spawns_info.get("player_4", spawn_p4.global_position)
		if p4_pos:
			spawn_p4.global_position = Vector2(p4_pos[0], p4_pos[1])
			top_left_pos = spawn_p4.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var b1_pos = spawns_info.get("bot_1", bot_spawn1.global_position)
		if b1_pos:
			bot_spawn1.global_position = Vector2(b1_pos[0], b1_pos[1])
			top_left_pos = bot_spawn1.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)

		var b2_pos = spawns_info.get("bot_2", bot_spawn2.global_position)
		if b2_pos:
			bot_spawn2.global_position = Vector2(b2_pos[0], b2_pos[1])
			top_left_pos = bot_spawn2.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)
			
		var b3_pos = spawns_info.get("bot_3", bot_spawn3.global_position)
		if b3_pos:
			bot_spawn3.global_position = Vector2(b3_pos[0], b3_pos[1])
			top_left_pos = bot_spawn3.global_position - Vector2(8, 8)
			tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
			spawn_rect = Rect2i(tile_pos, Vector2i(2, 2))
			_clear_tiles_at_rect(spawn_rect)
			
	else:
		base_area_position = "down"

	#print("Nível %s carregado com sucesso." % levelname)
	return true

func generate_default_list() -> Array:
	var list: Array = []
	for i in range(100):
		list.append(1)
	return list

func _on_save_message_timeout() -> void:
	in_popup = false
	level_saved_message.hide()
	mobile_layout()

func goto_menu():
	if Global.os_type == "desktop":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	MobileControl.control_mode("hidden")
	MenuState.skip_intro = true
	MenuState.start_in = 5
	LoadingScreen.play_transition_to_scene("res://scenes/menu/main_menu.tscn", "SUPER\nBATTLE\nCITY")

#endregion

#region DRAG AND DROP
func _get_snapped_mouse_pos() -> Vector2:
	return get_snapped_position(get_global_mouse_position(), 8)

func get_snapped_position(pos: Vector2, snap: int = 8) -> Vector2:
	return Vector2(
		round(pos.x / snap) * snap,
		round(pos.y / snap) * snap
	)

func _is_valid_spawn_location(spawn_global_pos: Vector2, spawn_being_dragged: Sprite2D) -> bool:
	var top_left_pos = spawn_global_pos - Vector2(8, 8)
	var tile_pos = terrain.local_to_map(terrain.to_local(top_left_pos))
	var new_spawn_tile_rect = Rect2i(tile_pos, Vector2i(2, 2))

	if not MAKER_BOUNDARY.encloses(new_spawn_tile_rect):
		return false

	for zone in exclusion_zones:
		if zone.intersects(new_spawn_tile_rect):
			return false

	for other_spawn in all_spawn_sprites:
		if other_spawn == spawn_being_dragged:
			continue 

		var other_top_left = other_spawn.global_position - Vector2(8, 8)
		var other_tile_pos = terrain.local_to_map(terrain.to_local(other_top_left))
		var other_spawn_tile_rect = Rect2i(other_tile_pos, Vector2i(2, 2))

		if new_spawn_tile_rect.intersects(other_spawn_tile_rect):
			return false

	return true

func _cancel_drag() -> void:
	if currently_dragged_spawn:
		currently_dragged_spawn.global_position = drag_start_position
		currently_dragged_spawn.modulate.a = 1.0

	currently_dragged_spawn = null
	drag_start_position = Vector2.ZERO

#endregion

func _on_hud_icon_pressed(icon_node: Node2D, mode: MakerMode) -> void:
	_cancel_drag()
	current_maker_mode = mode
	current_item_selected = icon_node
	option_selected.global_position = current_item_selected.global_position
	mobile_layout()

func _build_level_data_dictionary(popup_data: Dictionary) -> Dictionary:
	var all_spawns_info = {
		"base_position": base_area_position,
		"player_1": [spawn_p1.global_position.x, spawn_p1.global_position.y],
		"player_2": [spawn_p2.global_position.x, spawn_p2.global_position.y],
		"player_3": [spawn_p3.global_position.x, spawn_p3.global_position.y],
		"player_4": [spawn_p4.global_position.x, spawn_p4.global_position.y],
		"bot_1": [bot_spawn1.global_position.x, bot_spawn1.global_position.y],
		"bot_2": [bot_spawn2.global_position.x, bot_spawn2.global_position.y],
		"bot_3": [bot_spawn3.global_position.x, bot_spawn3.global_position.y]
	}
	var cur_area = player_base.protection_area.get(base_area_position, "down")
	for block in cur_area:
		terrain.set_cell(block, -1)
	var final_level_data = {
		"level_info": popup_data,
		"spawns_info": all_spawns_info,
		"tile_data": get_tile_data_for_saving()
	}
	generate_base()
	return final_level_data

func _on_export_requested(popup_data: Dictionary, levelname: String):
	var level_data = _build_level_data_dictionary(popup_data)
	if OS.get_name() == "Web":
		_web_export(level_data, levelname)
		_on_export_success()
	else:
		pending_export_data = level_data
		pending_export_levelname = levelname
		go_to_export_file()

## WEB EXPORT
func _web_export(level_data: Dictionary, levelname: String):
	var json_string = JSON.stringify(level_data, "\t")
	var temp_path = "user://temp_web_export.bcd"
	var file = FileAccess.open_encrypted_with_pass(temp_path, FileAccess.WRITE, "battle_tank_maker")
	if file:
		file.store_string(json_string)
		file.close()
		var file_read = FileAccess.open(temp_path, FileAccess.READ)
		var buffer = file_read.get_buffer(file_read.get_length())
		file_read.close()
		JavaScriptBridge.download_buffer(buffer, levelname + ".bcd")
		DirAccess.remove_absolute(temp_path)

## WINDOWS EXPORT
func go_to_export_file():
	DisplayServer.file_dialog_show(
		GameTranslation.get_translated_text("Export level..."),
		"*.bcd",
		pending_export_levelname + ".bcd",
		false,
		DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
		["*.bcd ; " + GameTranslation.get_translated_text("Super Battle City Files")],
		_on_file_dialog_result
	)

func _on_file_dialog_result(status: bool, selected_paths: PackedStringArray, _filter_index: int):
	if not status or selected_paths.size() == 0:
		return
	var path_to_save = selected_paths[0]
	_finalize_file_export(path_to_save)

func _finalize_file_export(path: String):
	var json_string = JSON.stringify(pending_export_data, "\t")
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "battle_tank_maker")
	if file:
		file.store_string(json_string)
		file.close()
		_on_export_success()
	else:
		SoundManager.play_sound("editor_error")

# EXPORT FINALIZED
func _on_export_success():
	save_level_window.hide()
	in_popup = false
	level_saved_message.show()
	save_message_timer.start()

func mobile_layout():
	match current_maker_mode:
		MakerMode.TILE:
			set_tile_action(true)
			MobileControl.control_mode("build1")
		MakerMode.BASE:
			MobileControl.control_mode("build2")
		MakerMode.SPAWNER:
			MobileControl.control_mode("build3")
