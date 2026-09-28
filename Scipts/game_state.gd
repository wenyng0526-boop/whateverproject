extends Node

var currency: int = 10:
	set(value):
		currency = value
		currency_changed.emit(currency)

var owned_cards: Array[card_resource] = []
const MAX_CARDS = 6
signal currency_changed(new_amount: int)
