extends Node

var currency: int = 100: #remember to change this to 5, 100 is for testing only
	set(value):
		currency = value
		currency_changed.emit(currency)

var deployed_cards: Array[card_resource] = []
var hand_cards: Array[card_resource] = []
const MAX_CARDS = 6
const MAX_HAND = 10
signal currency_changed(new_amount: int)

func check_for_duplicate():
	var fusion_happened := true
	while fusion_happened:
		fusion_happened = false
		for i in range(hand_cards.size()):
			for j in range(i+1,hand_cards.size()):
				var card = hand_cards[i]
				var duplicate = hand_cards[j]
				if card.name == duplicate.name and card.fusion_tier == duplicate.fusion_tier:
					fuse_cards(i,j)
					fusion_happened = true
					break
			if fusion_happened:
				break

func fuse_cards(index_a: int, index_b: int):
	var card_a = hand_cards[index_a]
	print("fusing: ",card_a.name)
	card_a.attack *= 2
	card_a.health *= 2
	card_a.fusion_tier += 1
	hand_cards.remove_at(index_b)
	
