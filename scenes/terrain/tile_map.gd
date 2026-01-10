extends TileMapLayer

#func destroy_tile(world_pos: Vector2):
	#var tile_pos = local_to_map(world_pos)
	#var data = get_cell_tile_data(0, tile_pos)
	#if data == null:
		#return
	#
	#var tile_type = data.get_custom_data("type")
	#
	#match tile_type:
		#"brick":
			#set_cell(0, tile_pos, -1)
		#"metal":
			#set_cell(0, tile_pos, -1)
