extends Control

@onready var bots1: Label = $AllBots1/Bots
@onready var bots2: Label = $AllBots2/Bots

@onready var lifesP1: Label = $LifeHudP1/Lifes
@onready var lifesP2: Label = $LifeHudP2/Lifes
@onready var lifesP3: Label = $LifeHudP3/Lifes
@onready var lifesP4: Label = $LifeHudP4/Lifes

@onready var starP1: AnimatedSprite2D = $StarsP1/Star
@onready var valueP1: Label = $StarsP1/Value
@onready var starP2: AnimatedSprite2D = $StarsP2/Star
@onready var valueP2: Label = $StarsP2/Value
@onready var starP3: AnimatedSprite2D = $StarsP3/Star
@onready var valueP3: Label = $StarsP3/Value
@onready var starP4: AnimatedSprite2D = $StarsP4/Star
@onready var valueP4: Label = $StarsP4/Value

@onready var scoreP1: Label = $ScoreP1/Score
@onready var scoreP2: Label = $ScoreP2/Score
@onready var scoreP3: Label = $ScoreP3/Score
@onready var scoreP4: Label = $ScoreP4/Score

@onready var life_hud_p1: Node2D = $LifeHudP1
@onready var life_hud_p2: Node2D = $LifeHudP2
@onready var life_hud_p3: Node2D = $LifeHudP3
@onready var life_hud_p4: Node2D = $LifeHudP4

@onready var stars_hud_p1: Node2D = $StarsP1
@onready var stars_hud_p2: Node2D = $StarsP2
@onready var stars_hud_p3: Node2D = $StarsP3
@onready var stars_hud_p4: Node2D = $StarsP4

@onready var score_hud_p2: Node2D = $ScoreP2
@onready var score_hud_p3: Node2D = $ScoreP3
@onready var score_hud_p4: Node2D = $ScoreP4

@onready var level: Label = $Level
@onready var revives: Label = $Revives

var players: int = 1

func _ready() -> void:
	Global.lifes_p1_changed.connect(update_p1_lifes_label)
	Global.lifes_p2_changed.connect(update_p2_lifes_label)
	Global.lifes_p3_changed.connect(update_p3_lifes_label)
	Global.lifes_p4_changed.connect(update_p4_lifes_label)
	Global.star_p1_changed.connect(update_p1_stars_icon)
	Global.star_p2_changed.connect(update_p2_stars_icon)
	Global.star_p3_changed.connect(update_p3_stars_icon)
	Global.star_p4_changed.connect(update_p4_stars_icon)
	Global.score_p1_changed.connect(update_p1_score_label)
	Global.score_p2_changed.connect(update_p2_score_label)
	Global.score_p3_changed.connect(update_p3_score_label)
	Global.score_p4_changed.connect(update_p4_score_label)
	Global.cut_tree_p1_changed.connect(update_p1_stars_icon)
	Global.cut_tree_p2_changed.connect(update_p2_stars_icon)
	Global.cut_tree_p3_changed.connect(update_p3_stars_icon)
	Global.cut_tree_p4_changed.connect(update_p4_stars_icon)
	Global.revives_changed.connect(update_revives_label)
	Global.current_level_changed.connect(update_level_label)
	Global.level_bots_changed.connect(update_bots_remaining)
	update_p1_lifes_label(Global.lifes_p1)
	update_p2_lifes_label(Global.lifes_p2)
	update_p3_lifes_label(Global.lifes_p3)
	update_p4_lifes_label(Global.lifes_p4)
	update_p1_stars_icon(Global.star_p1)
	update_p2_stars_icon(Global.star_p2)
	update_p3_stars_icon(Global.star_p3)
	update_p4_stars_icon(Global.star_p4)
	update_revives_label(Global.total_revives)
	update_level_label(Global.current_level)
	update_p1_score_label(Global.score_p1)
	update_p2_score_label(Global.score_p2)
	update_p3_score_label(Global.score_p3)
	update_p4_score_label(Global.score_p4)

func toggle_hud_itens():
	life_hud_p2.visible = players >= 2
	life_hud_p3.visible = players >= 3
	life_hud_p4.visible = players >= 4
	stars_hud_p2.visible = players >= 2
	stars_hud_p3.visible = players >= 3
	stars_hud_p4.visible = players >= 4
	score_hud_p2.visible = players >= 2
	score_hud_p3.visible = players >= 3
	score_hud_p4.visible = players >= 4

	define_hud_layout()

func define_hud_layout():
	if players == 1:
		life_hud_p1.position = Vector2(24.0, 104.0)
		stars_hud_p1.position = Vector2(24.0, 136.0)

	elif players == 2:
		life_hud_p1.position = Vector2(24.0, 104.0)
		stars_hud_p1.position = Vector2(24.0, 136.0)

		life_hud_p2.position = Vector2(296.0, 104.0)
		stars_hud_p2.position = Vector2(296.0, 136.0)

	elif players == 3:
		life_hud_p3.position = Vector2(296.0, 104.0)
		stars_hud_p3.position = Vector2(296.0, 136.0)

func update_p1_lifes_label(value):
	lifesP1.text = format_number(value)

func update_p2_lifes_label(value):
	lifesP2.text = format_number(value)

func update_p3_lifes_label(value):
	lifesP3.text = format_number(value)

func update_p4_lifes_label(value):
	lifesP4.text = format_number(value)

func update_p1_stars_icon(value):
	valueP1.text = str(value)
	if Global.cut_tree_p1:
		starP1.define_super_rank(value)
	else:
		starP1.define_rank(value)

func update_p2_stars_icon(value):
	valueP2.text = str(value)
	if Global.cut_tree_p2:
		starP2.define_super_rank(value)
	else:
		starP2.define_rank(value)

func update_p3_stars_icon(value):
	valueP3.text = str(value)
	if Global.cut_tree_p3:
		starP3.define_super_rank(value)
	else:
		starP3.define_rank(value)

func update_p4_stars_icon(value):
	valueP4.text = str(value)
	if Global.cut_tree_p2:
		starP4.define_super_rank(value)
	else:
		starP4.define_rank(value)

func update_p1_score_label(value):
	scoreP1.text = format_number(value, 6)

func update_p2_score_label(value):
	scoreP2.text = format_number(value, 6)

func update_p3_score_label(value):
	scoreP3.text = format_number(value, 6)

func update_p4_score_label(value):
	scoreP4.text = format_number(value, 6)

func update_revives_label(value):
	revives.text = format_number(value)

func update_level_label(value):
	level.text = format_number(value)

func update_bots_remaining(value):
	bots1.text = format_number(value)
	bots2.text = format_number(value)

func format_number(number: int, pad_value: int = 2) -> String:
	var number_string: String = str(number)
	return number_string.pad_zeros(pad_value)
