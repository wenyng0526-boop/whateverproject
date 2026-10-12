class_name RewardScreen
extends Control

@onready var success_screen1: Label = $Success_screen
@onready var success_screen2: Label = $Success_screen2
@onready var success_screen3: Label = $Success_screen3

@onready var failure_screen1: Label = $Failure_screen
@onready var failure_screen2: Label = $Failure_screen2
@onready var failure_screen3: Label = $Failure_screen3

@onready var success_reward: Label = $"Success_screen(reward)"
@onready var success_details: Label = $"Success_screen(reward)2"
@onready var failure_reward: Label = $"Failure_screen(reward)"

@onready var number_of_defeat_enemy: Label = $defeated_enemy_number
@onready var number_of_remaining_cards: Label = $remaining_cards_number

@export_file("*.tscn") var next_scene: String
@export_file("*.tscn") var menu_scene: String
@export_file("*.tscn") var failure_menu_scene: String


#success 
@export var success_continue_button: Button
@export var success_main_menu_button: Button
#failure
@export var failure_main_menu_button: Button

func _ready() -> void:
	hide()


func show_success(reward: int, defeated_enemy: int, remaining_cards: int) -> void:
	hide_all_screens()
	show()

	if GameState.returned_from_failure_or_load:
		success_screen3.show()
		GameState.returned_from_failure_or_load = false

	elif GameState.win_count > 5:
		success_screen1.show()

	else:
		success_screen2.show()

	success_reward.text = "$" + str(reward)
	number_of_defeat_enemy.text =  "$" + str(defeated_enemy)
	number_of_remaining_cards.text =  "$" + str(remaining_cards)

	success_reward.show()
	success_details.show()
	number_of_defeat_enemy.show()
	number_of_remaining_cards.show()
	success_continue_button.show()
	success_main_menu_button.show()


func show_failure() -> void:
	GameState.delete_save_game()

	hide_all_screens()
	show()

	var random_screen = randi_range(1, 3)

	if random_screen == 1:
		failure_screen1.show()
	elif random_screen == 2:
		failure_screen2.show()
	else:
		failure_screen3.show()

	failure_reward.show()
	failure_main_menu_button.show()


func hide_all_screens() -> void:
	success_screen1.hide()
	success_screen2.hide()
	success_screen3.hide()

	failure_screen1.hide()
	failure_screen2.hide()
	failure_screen3.hide()

	success_continue_button.hide()
	success_main_menu_button.hide()

	failure_main_menu_button.hide()

	success_reward.hide()
	number_of_defeat_enemy.hide()
	number_of_remaining_cards.hide()
	failure_reward.hide()


func _on_continue_button_pressed() -> void:
	if next_scene != "":
		GameState.complete_node()
		GameState.save_game("res://Scenes/map.tscn")
		get_tree().change_scene_to_file(next_scene)

func _menu_button_pressed() -> void:
	GameState.complete_node()
	GameState.save_game(next_scene)
	if menu_scene != "":
		get_tree().change_scene_to_file(menu_scene)

func _on_failure_main_menu_button_pressed() -> void:
	if failure_menu_scene != "":
		get_tree().change_scene_to_file(failure_menu_scene)
