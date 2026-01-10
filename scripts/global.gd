extends Node

enum GameMode { PLAY, MAKER }
var current_game_mode: GameMode = GameMode.MAKER

enum GamePlay { CAMPAIGN, FREEPLAY, CUSTOM, SURVIVAL }
var current_gameplay_mode: GamePlay = GamePlay.FREEPLAY

var current_level_number: int = 1
var current_level_name: String = ""
var current_level_players: int = 1

var hard_mode: bool = false
var bot_use_bonus: bool = false
var freeplay_to_campaign: bool = false
var auto_fire: bool = false
var language: String = "english"
var all_languages: Array = ["english", "espanol", "portugues"]
var original_languages: Array = ["english", "español", "português"]

var current_level_round: int = 1
var level_round_data: Dictionary = {
	"bots": 10,
	"time": 0.0,
	"extra": 0,
	"type": 1,
	"shield": 0,
	"active": 4,
}

var in_game_over: bool = false

signal level_bots_changed(new_total)

var level_bots: int = 20:
	set(value):
		level_bots = value
		level_bots_changed.emit(level_bots)

signal lifes_p1_changed(new_lifes)
signal lifes_p2_changed(new_lifes)
signal lifes_p3_changed(new_lifes)
signal lifes_p4_changed(new_lifes)

var lifes_p1: int = 2:
	set(value):
		lifes_p1 = value
		lifes_p1_changed.emit(lifes_p1)

var lifes_p2: int = 2:
	set(value):
		lifes_p2 = value
		lifes_p2_changed.emit(lifes_p2)

var lifes_p3: int = 2:
	set(value):
		lifes_p3 = value
		lifes_p3_changed.emit(lifes_p3)

var lifes_p4: int = 2:
	set(value):
		lifes_p4 = value
		lifes_p4_changed.emit(lifes_p4)

signal score_p1_changed(new_score)
signal score_p2_changed(new_score)
signal score_p3_changed(new_score)
signal score_p4_changed(new_score)

var score_p1: int = 0:
	set(value):
		score_p1 = value
		score_p1_changed.emit(score_p1)

var score_p2: int = 0:
	set(value):
		score_p2 = value
		score_p2_changed.emit(score_p2)

var score_p3: int = 0:
	set(value):
		score_p3 = value
		score_p3_changed.emit(score_p3)

var score_p4: int = 0:
	set(value):
		score_p4 = value
		score_p4_changed.emit(score_p4)

var next_extra_revive_score: int = 100000

var general_score: int = 0:
	set(value):
		general_score = value
		if general_score >= next_extra_revive_score and not in_game_over:
			next_extra_revive_score += 100000
			add_revives()

signal current_level_changed(new_level)
signal revives_changed(new_level)

var current_level: int = 1:
	set(value):
		current_level = value
		current_level_changed.emit(current_level)

var total_revives: int = 2:
	set(value):
		total_revives = value
		revives_changed.emit(total_revives)

signal star_p1_changed(new_stars)
signal star_p2_changed(new_stars)
signal star_p3_changed(new_stars)
signal star_p4_changed(new_stars)

var star_p1: int = 1:
	set(value):
		star_p1 = value
		star_p1_changed.emit(star_p1)

var star_p2: int = 1:
	set(value):
		star_p2 = value
		star_p2_changed.emit(star_p2)

var star_p3: int = 1:
	set(value):
		star_p3 = value
		star_p3_changed.emit(star_p3)

var star_p4: int = 1:
	set(value):
		star_p4 = value
		star_p4_changed.emit(star_p4)

var boat_p1: bool = false
var boat_p2: bool = false
var boat_p3: bool = false
var boat_p4: bool = false

signal cut_tree_p1_changed(cut)
signal cut_tree_p2_changed(cut)
signal cut_tree_p3_changed(cut)
signal cut_tree_p4_changed(cut)

var cut_tree_p1: bool = false:
	set(value):
		cut_tree_p1 = value
		cut_tree_p1_changed.emit(star_p1)
var cut_tree_p2: bool = false:
	set(value):
		cut_tree_p2 = value
		cut_tree_p2_changed.emit(star_p2)
var cut_tree_p3: bool = false:
	set(value):
		cut_tree_p3 = value
		cut_tree_p3_changed.emit(star_p3)
var cut_tree_p4: bool = false:
	set(value):
		cut_tree_p4 = value
		cut_tree_p4_changed.emit(star_p4)

var next_extra_life_score_p1: int = 50000
var next_extra_life_score_p2: int = 50000
var next_extra_life_score_p3: int = 50000
var next_extra_life_score_p4: int = 50000

func add_score(player: int, amount: int):
	match player:
		1:
			self.score_p1 += amount
			if score_p1 >= next_extra_life_score_p1 and not in_game_over:
				next_extra_life_score_p1 += 50000
				add_lifes(1)
		2:
			self.score_p2 += amount
			if score_p2 >= next_extra_life_score_p2 and not in_game_over:
				next_extra_life_score_p2 += 50000
				add_lifes(2)
		3:
			self.score_p3 += amount
			if score_p3 >= next_extra_life_score_p3 and not in_game_over:
				next_extra_life_score_p3 += 50000
				add_lifes(3)
		4:
			self.score_p4 += amount
			if score_p4 >= next_extra_life_score_p4 and not in_game_over:
				next_extra_life_score_p4 += 50000
				add_lifes(4)

func get_score(player: int) -> int:
	match player:
		1:
			return self.score_p1
		2:
			return self.score_p2
		3:
			return self.score_p3
		4:
			return self.score_p4
	return 0

func combine_scores():
	var total = score_p1 + score_p2 + score_p3 + score_p4
	general_score = total

func add_lifes(player: int, sound: bool = true):
	if sound:
		SoundManager.play_sound("one_up")
	match player:
		1:
			self.lifes_p1 += 1
		2:
			self.lifes_p2 += 1
		3:
			self.lifes_p3 += 1
		4:
			self.lifes_p4 += 1

func decrease_lifes(player: int):
	match player:
		1:
			self.lifes_p1 -= 1
			if lifes_p1 < 0:
				lifes_p1 = 0
		2:
			self.lifes_p2 -= 1
			if lifes_p2 < 0:
				lifes_p2 = 0
		3:
			self.lifes_p3 -= 1
			if lifes_p3 < 0:
				lifes_p3 = 0
		4:
			self.lifes_p4 -= 1
			if lifes_p4 < 0:
				lifes_p4 = 0

func get_lifes(player_id: int) -> int:
	match player_id:
		1:
			return self.lifes_p1
		2:
			return self.lifes_p2
		3:
			return self.lifes_p3
		4:
			return self.lifes_p4
	return 0

func add_stars(player: int):
	match player:
		1:
			self.star_p1 += 1
		2:
			self.star_p2 += 1
		3:
			self.star_p3 += 1
		4:
			self.star_p4 += 1

func decrease_stars(player: int):
	match player:
		1:
			self.star_p1 = 1
		2:
			self.star_p2 = 1
		3:
			self.star_p3 = 1
		4:
			self.star_p4 = 1

func get_stars(player: int) -> int:
	match player:
		1:
			return self.star_p1
		2:
			return self.star_p2
		3:
			return self.star_p3
		4:
			return self.star_p4
	return 1

func toggle_boat(player: int, state: bool):
	match player:
		1:
			self.boat_p1 = state
		2:
			self.boat_p2 = state
		3:
			self.boat_p3 = state
		4:
			self.boat_p4 = state

func get_boat_state(player: int) -> bool:
	match player:
		1:
			return self.boat_p1
		2:
			return self.boat_p2
		3:
			return self.boat_p3
		4:
			return self.boat_p4
	return false

func toggle_cut_tree(player: int, state: bool):
	match player:
		1:
			self.cut_tree_p1 = state
		2:
			self.cut_tree_p2 = state
		3:
			self.cut_tree_p3 = state
		4:
			self.cut_tree_p4 = state

func get_cut_tree_state(player: int) -> bool:
	match player:
		1:
			return self.cut_tree_p1
		2:
			return self.cut_tree_p2
		3:
			return self.cut_tree_p3
		4:
			return self.cut_tree_p4
	return false

func add_revives():
	SoundManager.play_sound("receive_revive")
	self.total_revives += 1

func decrease_revives():
	if total_revives == 0: return
	self.total_revives -= 1
	if total_revives < 0:
		total_revives = 0

func set_level(level: int):
	self.current_level = level

func set_level_bots(bots: int):
	level_bots = bots

func set_player_level(players: int):
	if players >= 1 and players <= 4:
		current_level_players = players
	else:
		current_level_players = 1

func decrease_level_bots():
	if level_bots > 0:
		level_bots -= 1

func check_and_update_highscore():
	var players = current_level_players
	if general_score > Highscore.get_highscore(players):
		Highscore.set_highscore(players, general_score)

func reset_game():
	current_game_mode = GameMode.MAKER
	current_gameplay_mode = GamePlay.FREEPLAY

	current_level_number = 1
	current_level_name = ""
	current_level_players = 1
	current_level = 1

	general_score = 0

	level_bots = 20

	lifes_p1 = 3
	lifes_p2 = 3
	lifes_p3 = 3
	lifes_p4 = 3

	score_p1 = 0
	score_p2 = 0
	score_p3 = 0
	score_p4 = 0

	star_p1 = 1
	star_p2 = 1
	star_p3 = 1
	star_p4 = 1
	
	boat_p1 = false
	boat_p2 = false
	boat_p3 = false
	boat_p4 = false
	
	cut_tree_p1 = false
	cut_tree_p2 = false
	cut_tree_p3 = false
	cut_tree_p4 = false

	next_extra_revive_score = 100000
	next_extra_life_score_p1 = 50000
	next_extra_life_score_p2 = 50000
	next_extra_life_score_p3 = 50000
	next_extra_life_score_p4 = 50000

	total_revives = 2

	current_level_round = 1
	level_round_data = {
		"bots": 10,
		"time": 0.0,
		"extra": 0,
		"type": 1,
		"shield": 0,
		"active": 4,
	}
	
	in_game_over = false

func set_level_round_data():
	if current_level_round % 2 == 0:
		if level_round_data["bots"] == 100:
			return
		level_round_data["bots"] += 2

	if current_level_round % 3 == 0:
		if level_round_data["time"] >= 3.0:
			return
		level_round_data["time"] += 0.2
	
	if current_level_round % 10 == 0:
		if level_round_data["extra"] >= 100:
			return
		level_round_data["extra"] += 5
	
	if current_level_round % 10 == 0:
		if level_round_data["type"] >= 4:
			return
		level_round_data["type"] += 1
	
	if current_level_round % 10 == 0:
		if level_round_data["shield"] >= 5:
			return
		level_round_data["shield"] += 1
	
	if current_level_round % 4 == 0:
		if level_round_data["active"] >= 14:
			return
		level_round_data["active"] += 1

func set_game_language(lang: String):
	TranslationServer.set_locale(lang)

func get_next_language():
	var index = all_languages.find(language)
	if index == all_languages.size() - 1:
		index = 0
	else:
		index += 1
	language = all_languages[index]
	set_game_language(language)

func get_original_language() -> String:
	var index = all_languages.find(language)
	return original_languages[index].to_upper()

func get_translated_text(text: String) -> String:
	var msg = TranslationServer.get_translation_object(Global.language).get_message(text)
	return msg
