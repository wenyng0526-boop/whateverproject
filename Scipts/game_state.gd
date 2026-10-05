extends Node

var currency: int = 100: #remember to change this to 5, 100 is for testing only
	set(value):
		currency = value
		currency_changed.emit(currency)

var deployed_cards: Array[card_resource] = []
var hand_cards: Array[card_resource] = []
const MAX_CARDS = 6
const MAX_HAND = 10
var shop_level: int = 1
const MAX_SHOP_LEVEL = 3
const SHOP_SLOTS = [4, 5, 6]        # index 0 = level 1, index 1 = level 2, index 2 = level 3
const SHOP_MAX_STAR = [2, 3, 4]     # highest star card allowed at each level
const SHOP_UPGRADE_COST = [10, 30]    # [0] = cost to go 1→2, [1] = cost to go 2→3
signal currency_changed(new_amount: int)

var win_count: int = 0
#for success screen3
var returned_from_failure_or_load: bool = false

#combat_scene(tutorial and normal)
enum CombatMode {
	TUTORIAL,
	NORMAL
}
var combat_mode: CombatMode = CombatMode.NORMAL
var current_wave: int = 1


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

#(save and load)
#——————————————————————————————————————————————
const SAVE_PATH = "user://savegame.json"

func has_save_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(resume_scene: String) -> void:
	var save_data = {
		"currency": currency,
		"win_count": win_count,
		"current_wave": current_wave,
		"resume_scene": resume_scene,
		"hand_cards": [],
		"deployed_cards": []
	}

	# Save every hand card as its own Resource
	for i in range(hand_cards.size()):
		var card_path = "user://hand_card_%d.tres" % i
		ResourceSaver.save(hand_cards[i], card_path)
		save_data["hand_cards"].append(card_path)

	# Save every deployed card as its own Resource
	for i in range(deployed_cards.size()):
		var card_path = "user://deployed_card_%d.tres" % i
		ResourceSaver.save(deployed_cards[i], card_path)
		save_data["deployed_cards"].append(card_path)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

	print("GAME SAVED")


func card_to_dict(card: card_resource) -> Dictionary:
	return {
		"name": card.name,
		"cost": card.cost,
		"attack": card.attack,
		"health": card.health,
		"fusion_tier": card.fusion_tier,
		"star": card.star,
		"minon_type": card.minon_type,
		"image_path": card.image.resource_path if card.image else ""
	}


func dict_to_card(data: Dictionary) -> card_resource:
	var card = card_resource.new()

	card.name = data["name"]
	card.cost = data["cost"]
	card.attack = data["attack"]
	card.health = data["health"]
	card.fusion_tier = data["fusion_tier"]
	card.star = data["star"]
	card.minon_type = data["minon_type"]

	if data["image_path"] != "":
		card.image = load(data["image_path"])

	return card


func load_game() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		print("NO SAVE FILE")
		return ""

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())

	if save_data == null:
		print("FAILED TO LOAD SAVE")
		return ""

	currency = int(save_data["currency"])
	win_count = int(save_data["win_count"])
	current_wave = int(save_data["current_wave"])

	hand_cards.clear()
	deployed_cards.clear()

	# Load hand cards
	for card_path in save_data["hand_cards"]:
		var card = load(card_path) as card_resource

		if card != null:
			hand_cards.append(card)

	# Load deployed cards
	for card_path in save_data["deployed_cards"]:
		var card = load(card_path) as card_resource

		if card != null:
			deployed_cards.append(card)

	returned_from_failure_or_load = true

	print("GAME LOADED")

	return save_data["resume_scene"]
	

func delete_save_game() -> void:
	var dir = DirAccess.open("user://")

	if dir == null:
		return

	# Delete the main save file
	if dir.file_exists("savegame.json"):
		dir.remove("savegame.json")

	# Delete all saved card resource files
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			if file_name.begins_with("hand_card_") or file_name.begins_with("deployed_card_"):
				dir.remove(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	print("ALL SAVE FILES DELETED")
