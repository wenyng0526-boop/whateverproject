extends CanvasLayer

@export var chest_icon: TextureRect

@export var closed_chest_texture: Texture2D
@export var good_open_texture: Texture2D
@export var bad_open_texture: Texture2D

@export var hint_label: Label
@export var result_label: Label
@export var click_area: Button
@export var continue_button: Button
@export var animation_player: AnimationPlayer
@export var leave_button: Button
@export var card_pool: shop_card

# Number of clicks required to open the chest
@export var clicks_to_open: int = 5

var current_clicks: int = 0
var chest_opened: bool = false


func _ready() -> void:
	result_label.hide()
	continue_button.hide()
	leave_button.show()

	chest_icon.texture = closed_chest_texture
	

func _on_click_area_pressed() -> void:
	if chest_opened:
		return

	current_clicks += 1

	# After the first click, the player can no longer leave
	if current_clicks == 1:
		leave_button.hide()

	# Restart the shake animation every click
	animation_player.stop()
	animation_player.play("shake")

	var clicks_left: int = clicks_to_open - current_clicks

	if clicks_left > 0:
		hint_label.text = "Keep clicking! %d more!" % clicks_left
		return

	chest_opened = true
	click_area.disabled = true

	await animation_player.animation_finished

	open_chest()

func open_chest() -> void:
	hint_label.hide()
	result_label.show()

	# 50% Good, 50% Bad
	if randf() < 0.5:
		chest_icon.texture = good_open_texture
		trigger_good_event()
	else:
		chest_icon.texture = bad_open_texture
		trigger_bad_event()


func trigger_good_event() -> void:
	# 50% Coins, 50% Card
	if randf() < 0.5:
		give_coins()
	else:
		give_card()


func give_coins() -> void:
	var amount: int = randi_range(1, 5)

	GameState.currency += amount

	result_label.text = "Lucky! You found %d coins!" % amount

	finish_chest()


func give_card() -> void:
	# Give coins instead if the hand is already full
	if GameState.hand_cards.size() >= GameState.MAX_HAND:
		give_coins()
		return

	# 50% 1-star, 50% 2-star
	var star: int = randi_range(1, 2)

	var possible_cards: Array[card_resource] = []

	for card in card_pool.shop_cards_one:
		if card.cost == star:
			possible_cards.append(card)

	if possible_cards.is_empty():
		give_coins()
		return

	var selected_card: card_resource = possible_cards.pick_random()

	# Make an independent copy
	var new_card: card_resource = selected_card.duplicate(true)

	GameState.hand_cards.append(new_card)

	# Fuse automatically if there is a duplicate
	GameState.check_for_duplicate()

	result_label.text = "Lucky! You found a %d-star %s!" % [
		star,
		new_card.name
	]

	finish_chest()


func trigger_bad_event() -> void:
	# 50% Lose a card, 50% Lose coins
	if randf() < 0.5:
		lose_random_card()
	else:
		lose_coins()


func lose_random_card() -> void:
	# Keep at least one card to prevent the player from getting stuck
	if GameState.hand_cards.size() <= 1:
		lose_coins()
		return

	var random_index: int = randi_range(
		0,
		GameState.hand_cards.size() - 1
	)

	var lost_card: card_resource = GameState.hand_cards[random_index]

	GameState.hand_cards.remove_at(random_index)

	result_label.text = "Mimic! It ate your %s!" % lost_card.name

	finish_chest()


func lose_coins() -> void:
	var wanted_loss: int = randi_range(1, 5)

	# Currency cannot go below 0
	var actual_loss: int = min(wanted_loss, GameState.currency)

	GameState.currency -= actual_loss

	result_label.text = "Mimic! You lost %d coins!" % actual_loss

	finish_chest()


func finish_chest() -> void:
	click_area.hide()
	leave_button.hide()
	continue_button.show()


func _on_continue_button_pressed() -> void:
	GameState.complete_node()

	GameState.save_game("res://Scenes/map.tscn")

	# Reload the map so the newly unlocked nodes refresh
	get_tree().reload_current_scene()


func _on_leave_button_pressed() -> void:
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().reload_current_scene()
