extends Node2D

@export var card_ui : PackedScene
@export var shop_cards : Resource
@export var card_container : HBoxContainer
@export var player_container : HBoxContainer
@export var hand_container : HBoxContainer
@export var confirm_panel : Control
@export var confirm_label : Label
@export var upgrade_button: Button

var refresh_cost = 1
var sell_value: int = 1
var pending_action: Callable
var is_fusing:bool = false

@onready var fan_sound: AudioStreamPlayer = $CardFan
@onready var card_draw: AudioStreamPlayer = $CardDraw
@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var blip_sound: AudioStreamPlayer = $BlipSound
@onready var fuse_sound: AudioStreamPlayer = $FuseSound
@onready var upgrade_sound: AudioStreamPlayer = $UpgradeSound
@onready var select_sound: AudioStreamPlayer = $SelectSound

@onready var tutorial_root: Control = $TutorialLayer/Control
@onready var dialogue_panel: NinePatchRect = $TutorialLayer/Control/DialoguePanel
@onready var dialogue_label: Label = $TutorialLayer/Control/DialoguePanel/Label

var tutorial_active: bool = true
var is_typing: bool = false
var skip_typing: bool = false
var next_line: bool = false
var tutorial_skipped: bool = false

@onready var skip_button: Button = $TutorialLayer/Control/SkipButton

var tutorial_lines: Array[String] = [
	"Hello there, I'm Ethan, the sole shopkeeper of this shop. This is where you buy minions to protect yourself from the enemies of this labyrinth.",
	"Minions each have their own attack and health stat, with the stars representing their cost. Each minion also have their own abilities, you may hover them to view their abilities.",
	"Clicking and buying a card places it in your hand. You may only hold a maximum of 10 cards at once.",
	"If you don't like what you see in the shop, you may refresh the shop, do note that it will always cost you 1 coin.",
	"If you have enough money, you may upgrade the shop, expanding my wares with stronger minions that will cost more.",
	"If you do buy any duplicate minions with the same stats, the two cards will FUSE! Doubling their stats, making them far stronger than before.",
	"Not enough money? You can also sell your cards to me from your hand, but I will only give you 1 coin in return. (It's business kid.)",
	"That's all, once you're done shopping you may leave by pressing the proceed button. Best of luck partner."
]

func _ready() -> void:
	refresh_shop()
	spawn_player_cards()
	refresh_hand()
	update_upgrade_label()
	await check_for_duplicate_animated()
	if not GameState.shop_tutorial_completed:
		await start_tutorial()
	else:
		tutorial_root.hide()

func refresh_shop():
	print("shop_level: ", GameState.shop_level)
	
	for child in card_container.get_children():
		card_container.remove_child(child)
		child.queue_free()

	fan_sound.play()
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
	if is_fusing:
		return
	var cost: int = card.card_data.cost
	var size = GameState.hand_cards.size()
	if GameState.currency < cost:
		print("YOU'RE BROKE")
		return

	if size == GameState.MAX_HAND and not _can_fuse_with_hand(card.card_data):
		print("YOUR HAND IS FULL")
		return
	_ask_confirm("Buy %s for %d coins?" % [card.card_data.name, cost], _buy_card.bind(card))

#fuse when hand deck full
func _can_fuse_with_hand(data: card_resource) -> bool:
	for existing in GameState.hand_cards:
		if existing.name == data.name and existing.fusion_tier == data.fusion_tier:
			return true
	return false

func _buy_card(card: CardUI) -> void:
	GameState.currency -= card.card_data.cost
	var new_card: card_resource = card.card_data.duplicate(true) #duplicate card resource so card in shop or enemy won't be affected by increased stats during player fusion
	GameState.hand_cards.append(new_card)
	card.queue_free()
	print("Bought ", card.card_data.name, " | coins left: ", GameState.currency)
	card_draw.play()
	refresh_hand()
	await get_tree().process_frame
	await check_for_duplicate_animated()

func check_for_duplicate_animated() -> void:
	is_fusing = true
	while true:
		var index_a := -1
		var index_b := -1
		# Find two matching cards in GameState.
		for i in range(GameState.hand_cards.size()):
			for j in range(i + 1, GameState.hand_cards.size()):
				var card_a = GameState.hand_cards[i]
				var card_b = GameState.hand_cards[j]
				
				if card_a.name == card_b.name \
				and card_a.fusion_tier == card_b.fusion_tier:
					index_a = i
					index_b = j
					break
					
			if index_a != -1:
				break
		# No more matching pairs.
		if index_a == -1:
			break
		 # Find the UI cards belonging to those exact resources.
		var visual_a: CardUI = null
		var visual_b: CardUI = null

		for child in hand_container.get_children():
			if child is CardUI:
				if child.card_data == GameState.hand_cards[index_a]:
					visual_a = child
				elif child.card_data == GameState.hand_cards[index_b]:
					visual_b = child

		# Avoid trying to animate cards that aren't on screen.
		if visual_a == null or visual_b == null:
			push_warning("Could not find both card visuals for fusion.")
			break
		fuse_sound.play()
		await visual_a.fusion_tween(visual_b)

		GameState.fuse_cards(index_a, index_b)
		visual_a.set_card_data(visual_a.card_data)

		await visual_a.play_fusion_animation()

		# Restore the normal Z order after fusion
		visual_a.card_visual.z_as_relative = true
		visual_b.card_visual.z_as_relative = true

		visual_a.card_visual.z_index = 0
		visual_b.card_visual.z_index = 0

		await get_tree().create_timer(0.3).timeout

		refresh_hand()
		await get_tree().process_frame
	is_fusing = false

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
		card_instance.z_index = sorted_hand.find(data) * 10
		card_instance.normal_z_index = card_instance.z_index
		card_instance.current_location = CardUI.CardLocation.HAND
		card_instance.clicked.connect(_on_hand_card_clicked)

#done button
func _on_done_button_pressed() -> void:
	if is_fusing:
		return
	if GameState.hand_cards.is_empty():
		await show_warning()
		return
	blip_sound.play()
	await blip_sound.finished
	GameState.complete_node()
	GameState.save_game("res://Scenes/map.tscn")
	get_tree().change_scene_to_file("res://Scenes/map.tscn")

func start_tutorial():
	tutorial_active = true
	tutorial_skipped = false
	tutorial_root.show()
	dialogue_panel.show()
	for line in tutorial_lines:
		if tutorial_skipped:
			break
		await type_dialogue(line)
		if tutorial_skipped:
			break
	
	dialogue_panel.hide()
	tutorial_root.hide()
	tutorial_active = false
	
	GameState.shop_tutorial_completed = true
	
func type_dialogue(line: String):
	is_typing = true
	skip_typing = false
	next_line = false

	dialogue_label.text = line
	dialogue_label.visible_characters = 0

	for i in range(line.length()):
		if skip_typing:
			break
		dialogue_label.visible_characters = i + 1
		await get_tree().create_timer(0.04).timeout

	dialogue_label.visible_characters = -1
	is_typing = false

	while not next_line and not tutorial_skipped:
		await get_tree().process_frame
		
func _input(event: InputEvent) -> void:
	if not tutorial_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Let clicks on the Skip button pass through to the button itself
		if skip_button and skip_button.get_global_rect().has_point(event.position):
			return

		if is_typing:
			skip_typing = true
		else:
			next_line = true
			select_sound.play()
		get_viewport().set_input_as_handled()

func _on_skip_button_pressed() -> void:
	print("SKIP PRESSED")
	tutorial_active = false
	skip_typing = true
	next_line = true
	tutorial_skipped = true
	
	GameState.shop_tutorial_completed = true
	
	dialogue_panel.hide()
	tutorial_root.hide()

func show_warning() -> void:
	
	tutorial_root.show()
	dialogue_panel.show()
	dialogue_label.show()

	dialogue_label.text = "Please buy at least one card before you leave."
	dialogue_label.visible_characters = -1

	await get_tree().create_timer(2.5).timeout

	tutorial_root.hide()
	dialogue_label.hide()

#sell shet
func _on_hand_card_clicked(card: CardUI) -> void:
	if is_fusing:
		return
	_ask_confirm("Sell %s for %d coins?" % [card.card_data.name, sell_value], _sell_hand_card.bind(card))

func _sell_hand_card(card: CardUI) -> void:
	var index: int = GameState.hand_cards.find(card.card_data)
	print("Sold ", card.card_data.name, " | coins left: ", GameState.currency + sell_value)
	coin_sound.play()
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

	upgrade_sound.play()
	GameState.currency -= cost
	GameState.shop_level += 1
	refresh_shop()
	update_upgrade_label()
	print("Shop upgraded to level ", GameState.shop_level)

func update_upgrade_label() -> void:
	if not upgrade_button:
		return

	if GameState.shop_level >= GameState.MAX_SHOP_LEVEL:
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true
	else:
		var cost: int = GameState.SHOP_UPGRADE_COST[GameState.shop_level - 1]
		upgrade_button.text = "Upgrade $%d" % cost
		upgrade_button.disabled = false
