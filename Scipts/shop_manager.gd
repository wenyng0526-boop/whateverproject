extends Node2D

@export var card_ui : PackedScene
@export var shop_cards : Resource
@export var card_container : HBoxContainer
@export var player_container : HBoxContainer
@export var hand_container : HBoxContainer
@export var confirm_panel : Control
@export var confirm_label : Label

var refresh_cost = 1
var sell_value: int = 1
var pending_action: Callable

func _ready() -> void:
	refresh_shop()
	spawn_player_cards()
	refresh_hand()

func refresh_shop():
	print("shop_level: ", GameState.shop_level)

	for child in card_container.get_children():
		child.queue_free()

	var max_cost: int = GameState.SHOP_MAX_COST[GameState.shop_level - 1]
	var pool: Array[card_resource] = shop_cards.shop_cards_one.filter(
		func(c): return c.cost <= max_cost
	)

	var shop_size: int = GameState.SHOP_SLOTS[GameState.shop_level - 1]

	for i in range(shop_size):
		var random_card_data: card_resource = pool.pick_random()
		var card_instance : CardUI = card_ui.instantiate()
		card_container.add_child(card_instance)
		card_instance.set_card_data(random_card_data)
		card_instance.current_location = CardUI.CardLocation.SHOP
		card_instance.clicked.connect(_on_card_clicked)

func spawn_player_cards() -> void:
	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()

	for data in GameState.deployed_cards:
		var card_instance: CardUI = card_ui.instantiate()
		player_container.add_child(card_instance)
		card_instance.set_card_data(data)
		card_instance.current_location = CardUI.CardLocation.HAND
		card_instance.clicked.connect(_on_hand_card_clicked)

func _on_refresh_button_pressed() -> void:
	if GameState.currency >= refresh_cost:
		GameState.currency -= refresh_cost
		refresh_shop()

	else:
		print("YOU'RE BROKE")

func _on_card_clicked(card: CardUI) -> void:
	var cost: int = card.card_data.cost
	var size = GameState.hand_cards.size()
	if GameState.currency < cost:
		print("YOU'RE BROKE")
		return

	if size == GameState.MAX_HAND:
		print("YOUR HAND IS FULL")
		return
	_ask_confirm("Buy %s for %d coins?" % [card.card_data.name, cost], _buy_card.bind(card))

func _buy_card(card: CardUI) -> void:
	GameState.currency -= card.card_data.cost
	var new_card: card_resource = card.card_data.duplicate(true) #duplicate card resource so card in shop or enemy won't be affected by increased stats during player fusion
	GameState.hand_cards.append(new_card)
	card.queue_free()
	print("Bought ", card.card_data.name, " | coins left: ", GameState.currency)
	GameState.check_for_duplicate()
	refresh_hand()

#---------------------hand deck pro max--------------------------#
func refresh_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()

	var sorted_hand: Array[card_resource] = GameState.hand_cards.duplicate()
	sorted_hand.sort_custom(func(a, b):
		if a.name == b.name:
			return a.fusion_tier > b.fusion_tier # higher level on the left
		return a.name < b.name
	)

	for data in sorted_hand:
		var card_instance: CardUI = card_ui.instantiate()
		hand_container.add_child(card_instance)
		card_instance.set_card_data(data)
		card_instance.current_location = CardUI.CardLocation.HAND
		card_instance.clicked.connect(_on_hand_card_clicked)

#done button
func _on_done_button_pressed() -> void:
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")

#sell shet
func _on_hand_card_clicked(card: CardUI) -> void:
	if GameState.hand_cards.size() <= 1:
		print("YOU NEED AT LEAST ONE CARD")
		return
	_ask_confirm("Sell %s for %d coins?" % [card.card_data.name, sell_value], _sell_hand_card.bind(card))

func _sell_hand_card(card: CardUI) -> void:
	var index: int = card.get_index()
	print("Sold ", card.card_data.name, " | coins left: ", GameState.currency + sell_value)
	GameState.hand_cards.remove_at(index)
	GameState.currency += sell_value
	refresh_hand()

#---------------------Confirm--------------------------#
func _ask_confirm(message: String, action: Callable) -> void:
	pending_action = action
	confirm_label.text = message
	confirm_panel.show()

func _on_yes_button_pressed() -> void:
	confirm_panel.hide()
	if pending_action.is_valid():
		pending_action.call()
	pending_action = Callable()

func _on_no_button_pressed() -> void:
	confirm_panel.hide()
	pending_action = Callable()

#---------------------Shop upgrade--------------------------#
func _on_upgrade_button_pressed() -> void:
	if GameState.shop_level >= GameState.MAX_SHOP_LEVEL:
		print("SHOP IS MAX LEVEL")
		return

	var cost: int = GameState.SHOP_UPGRADE_COST[GameState.shop_level - 1]
	if GameState.currency < cost:
		print("YOU'RE BROKE")
		return

	GameState.currency -= cost
	GameState.shop_level += 1
	refresh_shop()
	print("Shop upgraded to level ", GameState.shop_level)
