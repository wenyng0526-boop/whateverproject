extends Node2D

@export var card_ui : PackedScene
@export var shop_cards : Resource
@export var card_container : HBoxContainer
@export var player_container: HBoxContainer

var shop_size: int = 4
var refresh_cost = 1

func _ready() -> void:
	refresh_shop()

func refresh_shop():
	for child in card_container.get_children():
		child.queue_free() #clear existing cards in the shop
	for i in range(shop_size):
		var random_card_data: card_resource = shop_cards.shop_cards_one.pick_random()
		var card_instance : CardUI = card_ui.instantiate()
		card_container.add_child(card_instance) 
		card_instance.set_card_data(random_card_data) #refill shop with new cards
		card_instance.clicked.connect(_on_card_clicked)
		
func spawn_player_cards() -> void:
	# If nothing was bought, keep the hand-placed test cards in the scene
	if GameState.owned_cards.is_empty():
		return

	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()

	for data in GameState.owned_cards:
		var card_instance: CardUI = card_ui.instantiate()
		player_container.add_child(card_instance)
		card_instance.set_card_data(data)
		
func _on_refresh_button_pressed() -> void:
	if GameState.currency >= refresh_cost:
		GameState.currency -= refresh_cost
		refresh_shop()
	else:
		print("YOU'RE BROKE")

func _on_card_clicked(card: CardUI) -> void:
	var cost: int = card.card_data.cost
	var size = GameState.owned_cards.size()
	if GameState.currency < cost:
		print("YOU'RE BROKE")
		return
	if size == GameState.MAX_CARDS:
		print("YOUR BOARD IS FULL")
		return
	GameState.currency -= cost
	GameState.owned_cards.append(card.card_data)
	spawn_player_cards()
	card.queue_free()
	print("Bought ", card.card_data.name, " | coins left: ", GameState.currency)

func _on_done_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/combat_scene.tscn")
