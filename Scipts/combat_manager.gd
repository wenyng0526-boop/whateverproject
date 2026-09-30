extends Node
class_name CombatManager

# The container that holds all Player cards
@export var player_container: HBoxContainer
# The container that holds all Enemy cards
@export var enemy_container: HBoxContainer
# The card scene used to spawn the player's bought cards
@export var card_ui: PackedScene
#add claw effect
@onready var effects: Node2D = $Effects
const claw_effect = preload("res://Scenes/claw_effect.tscn")
#add scene of printdamgae
const print_damage = preload("res://Scenes/print_damage.tscn")

var player_cards: Array[CardUI] = []
var enemy_cards: Array[CardUI] = []

var player_index: int = 0
var enemy_index: int = 0

func _ready() -> void:
	spawn_player_cards()
	await get_tree().process_frame
	setup_combat()
	await start_combat()


func setup_combat() -> void:
	player_cards.clear()
	enemy_cards.clear()
	
	for child in player_container.get_children():
		if child is CardUI:
			child.team = "Player"
			player_cards.append(child)

	for child in enemy_container.get_children():
		if child is CardUI:
			child.team = "Enemy"
			enemy_cards.append(child)

	print("Player cards: ", player_cards.size())
	print("Enemy cards: ", enemy_cards.size())

func spawn_player_cards() -> void:
	# If nothing was bought, keep the hand-placed test cards in the scene
	if GameState.deployed_cards.is_empty():
		return

	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()

	for data in GameState.deployed_cards:
		var card_instance: CardUI = card_ui.instantiate()
		player_container.add_child(card_instance)
		card_instance.set_card_data(data)

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
		print("PLAYER WINS!")
	elif player_cards.is_empty():
		print("ENEMY WINS!")


func attack(attacker: CardUI, target: CardUI) -> void:
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
	damage_instance.show_damage(attacker.current_attack)
	
	target.take_damage(attacker.current_attack)
	await target.play_hit_animation()
	
	#put the death anim here if have
	if target.is_dead():
		await get_tree().create_timer(1.0).timeout

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

			# Move the turn index back if a card before it was removed
			if dead_index < enemy_index:
				enemy_index -= 1

			enemy_cards.erase(card)
			card.die()
