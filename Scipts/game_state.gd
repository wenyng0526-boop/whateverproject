extends Node

var currency: int = 5:
	set(value):
		currency = value
		currency_changed.emit(currency)

var deployed_cards: Array[card_resource] = []
var hand_cards: Array[card_resource] = []
const MAX_CARDS = 6
const MAX_HAND = 10
signal currency_changed(new_amount: int)
