extends Node2D

@export var card_ui : PackedScene
@export var shop_cards : Resource
@export var card_container : HBoxContainer

var shop_size: int = 4
var player_currency: int = 10
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


func _on_refresh_button_pressed() -> void:
	if player_currency >= refresh_cost:
		player_currency -= refresh_cost
		refresh_shop()
	else:
		print("YOU'RE BROKE")
