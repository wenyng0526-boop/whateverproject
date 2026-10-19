extends Node
class_name CombatManager

# The container that holds all Player cards
@export var player_container: HBoxContainer
#drag card
@onready var player_drop_area: Control = $PlayerCenter
@onready var drag_layer: Control = $DragLayer
# The container that holds all Enemy cards
@export var enemy_container: HBoxContainer
#hand card
@onready var hand_container: HBoxContainer = $HandCenter/HandContainer
# The card scene used to spawn the player's bought cards
@export var card_ui: PackedScene
@onready var reward_screen: RewardScreen = $ResultLayer/Reward_scene
#add claw effect
@onready var effects: Node2D = $Effects
const claw_effect = preload("res://Scenes/claw_effect.tscn")
const print_damage = preload("res://Scenes/print_damage.tscn")
@export var one_star_enemies: Array[card_resource]
@export var two_star_enemies: Array[card_resource]
@export var three_star_enemies: Array[card_resource]
#Leave a space when dragging
var board_placeholder: Control

var player_cards: Array[CardUI] = []
var enemy_cards: Array[CardUI] = []


var player_index: int = 0
var enemy_index: int = 0
var defeated_enemy_cost: int = 0
var defeated_enemy_count: int = 0

var battle_started: bool = false


func _ready() -> void:
	spawn_player_cards()
	spawn_hand_cards()

	if GameState.combat_mode == GameState.CombatMode.NORMAL:
		var combat_number: int = GameState.win_count + 1
		spawn_random_enemies(combat_number)
	else:
		battle_started = true
		await get_tree().process_frame
		setup_combat()
		for card in player_cards:
			card.board_drag_enabled = false

		await start_combat()

func spawn_hand_cards() -> void:
	# Clear the current hand UI
	for child in hand_container.get_children():
		child.queue_free()

	# Create one CardUI for every card stored in the player's hand
	for data in GameState.hand_cards:
		var card_instance: CardUI = card_ui.instantiate()
		hand_container.add_child(card_instance)
		card_instance.set_card_data(data)
		card_instance.current_location = CardUI.CardLocation.HAND

		# Connect this hand card's click signal
		card_instance.clicked.connect(_on_hand_card_clicked)


func _on_board_card_drag_started(card: CardUI) -> void:
	var old_global_position = card.global_position

	# Move the dragged card out of the HBoxContainer
	card.reparent(drag_layer)

	# Keep the dragged card at the same screen position
	card.global_position = old_global_position

	# Force the board containers to update their layout
	player_container.queue_sort()
	$PlayerCenter.queue_sort()


func _on_hand_card_clicked(card: CardUI) -> void:
	if battle_started:
		return

	if GameState.deployed_cards.size() >= GameState.MAX_CARDS:
		print("BOARD IS FULL")
		return

	# Find card inside the hand data
	var hand_index = GameState.hand_cards.find(card.card_data)

	if hand_index == -1:
		return

	# Move the card data from hand to board
	var card_data = GameState.hand_cards[hand_index]
	GameState.hand_cards.remove_at(hand_index)
	GameState.deployed_cards.append(card_data)

	# Refresh both areas
	spawn_hand_cards()
	spawn_player_cards()


func _on_start_battle_button_pressed() -> void:
	if GameState.deployed_cards.is_empty():
		print("YOU NEED AT LEAST ONE CARD")
		return

	battle_started = true

	# Disable board card dragging during combat
	for child in player_container.get_children():
		if child is CardUI:
			child.board_drag_enabled = false

	hand_container.hide()
	$StartBattleButton.hide()

	await get_tree().process_frame

	setup_combat()
	await start_combat()

func setup_combat() -> void:
	player_cards.clear()
	enemy_cards.clear()

	defeated_enemy_cost = 0
	defeated_enemy_count = 0

	for child in player_container.get_children():
		if child is CardUI:
			child.team = "Player"
			child.board_drag_enabled = false
			player_cards.append(child)

	for child in enemy_container.get_children():
		if child is CardUI:
			child.team = "Enemy"
			child.board_drag_enabled = false
			enemy_cards.append(child)

	print("Player cards: ", player_cards.size())
	print("Enemy cards: ", enemy_cards.size())

func spawn_player_cards() -> void:
	# Keep the hand-placed tutorial cards
	if GameState.combat_mode == GameState.CombatMode.TUTORIAL:
		return

	# Clear the current board UI
	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()

	# Spawn all deployed cards
	for data in GameState.deployed_cards:
		var card_instance: CardUI = card_ui.instantiate()
		player_container.add_child(card_instance)
		card_instance.set_card_data(data)
		card_instance.current_location = CardUI.CardLocation.BOARD

		# Allow player board cards to be dragged during deployment
		card_instance.board_drag_enabled = true
	
		# Connect board card click
		card_instance.clicked.connect(_on_board_card_clicked)

		# Connect board card drag
		card_instance.board_drag_started.connect(_on_board_card_drag_started)
		card_instance.board_drag_moved.connect(_on_board_card_drag_moved)
		card_instance.board_drag_ended.connect(_on_board_card_drag_ended)


func _on_board_card_clicked(card: CardUI) -> void:
	if battle_started:
		return

	# Do not move the card if the hand is full
	if GameState.hand_cards.size() >= GameState.MAX_HAND:
		print("HAND IS FULL")
		return

	# Find this card inside the board data
	var board_index = GameState.deployed_cards.find(card.card_data)

	if board_index == -1:
		return

	# Move the card data from board back to hand
	var card_data = GameState.deployed_cards[board_index]
	GameState.deployed_cards.remove_at(board_index)
	GameState.hand_cards.append(card_data)

	# Refresh both areas
	spawn_player_cards()
	spawn_hand_cards()


func _on_board_card_drag_moved(card: CardUI, drag_position: Vector2) -> void:
	if battle_started:
		return

	# Remove the placeholder while the mouse is outside the board
	if not player_drop_area.get_global_rect().has_point(drag_position):
		remove_board_placeholder()
		return

	# Create a placeholder when the dragged card enters the board
	if board_placeholder == null:
		board_placeholder = Control.new()
		board_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_placeholder.custom_minimum_size = card.size
		player_container.add_child(board_placeholder)

	var new_index = 0

	# Find which gap the mouse is currently over
	for child in player_container.get_children():
		if child == board_placeholder:
			continue

		if child is CardUI:
			var card_center_x = child.get_global_rect().get_center().x

			if drag_position.x > card_center_x:
				new_index += 1

	# Move the invisible placeholder to that position
	player_container.move_child(board_placeholder, new_index)
	player_container.queue_sort()
	


func remove_board_placeholder() -> void:
	if board_placeholder == null:
		return

	player_container.remove_child(board_placeholder)
	board_placeholder.queue_free()
	board_placeholder = null

	player_container.queue_sort()
	$PlayerCenter.queue_sort()
	

func _on_board_card_drag_ended(card: CardUI, drop_position: Vector2) -> void:
	if battle_started:
		card.queue_free()
		spawn_player_cards()
		return

	# Return the card if it was dropped outside the board area
	if not player_drop_area.get_global_rect().has_point(drop_position):
		card.queue_free()
		spawn_player_cards()
		return

	var old_index = GameState.deployed_cards.find(card.card_data)

	if old_index == -1:
		card.queue_free()
		spawn_player_cards()
		return

	var card_data = GameState.deployed_cards[old_index]

	# Find the new position based on the mouse X position
	var new_index = 0

	for child in player_container.get_children():
		if child is CardUI:
			var card_center_x = child.get_global_rect().get_center().x

			if drop_position.x > card_center_x:
				new_index += 1

	# Remove the card from its old position
	GameState.deployed_cards.remove_at(old_index)

	# Insert it into the new position
	GameState.deployed_cards.insert(new_index, card_data)

	# Remove the dragged UI and rebuild the board
	card.queue_free()
	spawn_player_cards()
	

func start_combat() -> void:
	player_index = 0
	enemy_index = 0

	while not player_cards.is_empty() and not enemy_cards.is_empty():
		# PLAYER ATTACK
		if player_index >= player_cards.size():
			player_index = 0

		var player_attacker: CardUI = player_cards[player_index]
		var enemy_target: CardUI = enemy_cards[0]

		await attack(player_attacker, enemy_target)
		cleanup_dead_cards()

		if enemy_cards.is_empty():
			break

		player_index += 1
		await get_tree().create_timer(0.5).timeout

		# ENEMY ATTACK
		if enemy_index >= enemy_cards.size():
			enemy_index = 0

		var enemy_attacker: CardUI = enemy_cards[enemy_index]
		var player_target: CardUI = player_cards[0]

		await attack(enemy_attacker, player_target)
		cleanup_dead_cards()

		if player_cards.is_empty():
			break

		enemy_index += 1
		await get_tree().create_timer(0.5).timeout

	if enemy_cards.is_empty():
		var remaining_cards = player_cards.size()
		var reward = defeated_enemy_cost + remaining_cards
		
		var goblin_bonus = goblin_bonus()
		reward += goblin_bonus
		
		GameState.win_count += 1
		GameState.currency += reward
		
		print("Goblin survival bonus: +", goblin_bonus, " currency")
		# Return surviving cards to the hand after winning
		return_surviving_cards_to_hand()
	
		reward_screen.show_success(
			reward,
			defeated_enemy_count,
			remaining_cards
	)

	elif player_cards.is_empty():
		# Clear deployed cards because all player cards are dead
		return_surviving_cards_to_hand()

		GameState.returned_from_failure_or_load = true
		reward_screen.show_failure()


func attack(attacker: CardUI, target: CardUI) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var damage: int = attacker.current_attack
	#skeleton effect
	if attacker.card_data != null:
		if attacker.card_data.minon_type == card_resource.type.Skeleton:
			if randf() < 0.5:
				if attacker.card_data.name != "Arm":
					damage *= 2
					print("Skeleton double damage!")
				
	print(attacker.card_data.name, " attacks ", target.card_data.name, " for ", attacker.current_attack, " damage!")

	# Start the attack animation
	attacker.play_attack_animation()

	# Wait until the animation reaches the hit point
	await attacker.attack_hit

	# Create a new claw effect
	var claw_instance = claw_effect.instantiate()
	# Add the claw effect to the scene
	effects.add_child(claw_instance)

	# Move the claw effect to the target card
	claw_instance.global_position = target.get_global_rect().get_center()
	
	var damage_instance = print_damage.instantiate()
	# Add the damage number into the Scene Tree
	effects.add_child(damage_instance)
	
	# Move the damage number slightly above the target card
	damage_instance.global_position = target.get_global_rect().get_center() + Vector2(0, -50)
	damage_instance.show_damage(damage)
	
	target.take_damage(damage)
	await target.play_hit_animation()
	
	#put the death anim here if have
	if target.is_dead():
		await get_tree().create_timer(1.0).timeout
	
	if attacker.card_data.minon_type == card_resource.type.Rat:
		await trigger_rat_effect(attacker)
		
	await get_tree().create_timer(1.0).timeout


func cleanup_dead_cards() -> void:
	for card in player_cards.duplicate():
		if card.is_dead():
			var dead_index = player_cards.find(card)

			# Move the turn index back if a card before it was removed
			if dead_index < player_index:
				player_index -= 1

			player_cards.erase(card)
			card.die()

	for card in enemy_cards.duplicate():
		if card.is_dead():
			var dead_index = enemy_cards.find(card)

			# Add the defeated enemy's star value to the reward
			defeated_enemy_cost += card.card_data.cost
			defeated_enemy_count += 1

			# Move the turn index back if a card before it was removed
			if dead_index < enemy_index:
				enemy_index -= 1

			enemy_cards.erase(card)
			card.die()


func return_surviving_cards_to_hand() -> void:
	# Return surviving player cards to the hand
	for card in player_cards:
		GameState.hand_cards.append(card.card_data)

	# No cards should remain deployed after the battle
	GameState.deployed_cards.clear()


func spawn_random_enemies(combat_number: int) -> void:
	for child in enemy_container.get_children():
		enemy_container.remove_child(child)
		child.queue_free()

	var enemy_count: int = roll_enemy_count(combat_number)

	for i in range(enemy_count):
		var enemy_cost: int = roll_enemy_cost(combat_number)
		var enemy_data: card_resource

		if enemy_cost == 1:
			enemy_data = one_star_enemies.pick_random()
		elif enemy_cost == 2:
			enemy_data = two_star_enemies.pick_random()
		else:
			enemy_data = three_star_enemies.pick_random()

		var card_instance: CardUI = card_ui.instantiate()
		enemy_container.add_child(card_instance)
		card_instance.set_card_data(enemy_data)


func roll_enemy_cost(combat_number: int) -> int:
	var roll := randf()

	# Combat 1-2: only Cost 1 enemies
	if combat_number <= 2:
		return 1

	# Combat 3-4
	elif combat_number <= 4:
		if roll < 0.20:
			return 2

		return 1

	# Combat 5-6
	elif combat_number <= 6:
		if roll < 0.05:
			return 3
		elif roll < 0.40:
			return 2

		return 1

	# Combat 7-8
	elif combat_number <= 8:
		if roll < 0.15:
			return 3
		elif roll < 0.60:
			return 2

		return 1

	# Combat 9+
	else:
		if roll < 0.30:
			return 3
		elif roll < 0.75:
			return 2

		return 1


func roll_enemy_count(combat_number: int) -> int:
	if combat_number <= 2:
		return 2

	elif combat_number <= 4:
		return randi_range(2, 3)

	elif combat_number <= 6:
		return randi_range(3, 4)

	elif combat_number <= 8:
		return randi_range(4, 5)

	else:
		return randi_range(5, 6)


#rat effect
func get_living_enemies(attacker: CardUI) -> Array[CardUI]:
	var enemies: Array[CardUI] = []
	
	if attacker.team == "Player":
		enemies = enemy_cards
	else:
		enemies = player_cards
		
	var living_enemies: Array[CardUI] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead():
			living_enemies.append(enemy)
	return living_enemies

func trigger_rat_effect(attacker: CardUI) -> void:
	if not is_instance_valid(attacker):
		return
	
	if attacker.card_data == null:
		return
	var targets = get_living_enemies(attacker)
	var data: card_resource = attacker.card_data
	
	if data.rat_damage != 0:
		for i in range(data.rat_hits):
			var target: CardUI = targets.pick_random()
			if targets.is_empty():
				break
			await deal_effect_damage(
				attacker,
				target,
				data.rat_damage
			)
	
	if data.rat_aoe_damage != 0:
		for target in targets:
			if is_instance_valid(target) and not target.is_dead():
				await deal_effect_damage(
					attacker,
					target,
					data.rat_aoe_damage
				)

func deal_effect_damage(
	attacker: CardUI,
	target: CardUI,
	amount: int
) -> void:
	if not is_instance_valid(target) or target.is_dead():
		return
	
	var damage_instance = print_damage.instantiate()
	effects.add_child(damage_instance)
	
	damage_instance.global_position = (
		target.get_global_rect().get_center()
		+ Vector2(0, -50)
	)
	
	damage_instance.show_damage(amount)
	target.take_damage(amount)
	await target.play_hit_animation()
#goblin bonus money
func goblin_bonus():
	var bonus_currency: int = 0
	
	for card in player_cards:
		if not is_instance_valid(card) or card.is_dead():
			continue
		if card.card_data == null:
			continue
		
		var data: card_resource = card.card_data as card_resource
		
		if data.minon_type == card_resource.type.Goblin:
			bonus_currency += data.goblin_money
			
	return bonus_currency
