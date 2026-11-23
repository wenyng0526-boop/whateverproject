extends CombatManager

@export var test_boss_data: card_resource
@export var phase_two_boss_data: card_resource
@export var boss_max_health: int = 150
@export var boss_reward_coins: int = 5

@onready var intro_root: Control = $IntroLayer/IntroRoot
@onready var fade: ColorRect = $IntroLayer/IntroRoot/Fade
@onready var dialogue_panel: NinePatchRect = $IntroLayer/IntroRoot/DialoguePanel
@onready var dialogue_text: Label = $IntroLayer/IntroRoot/DialoguePanel/DialogueText
@onready var boss_health_bar: TextureProgressBar = $BossUILayer/BossHealthBar
@onready var attack_anim: AnimationPlayer = $BossUILayer/BossAnimation
@onready var attack_events: Node = $BossUILayer/AttackEvents
@onready var dodge_hint: CanvasLayer = $DodgeHintLayer

var opening_lines: Array[String] = [
	"Faster than I expected, human.",
	"But you shall go no farther. You will remain here forever, and your power will help me break the seal and bring destruction upon this foolish world."
]

var phase_two_lines: Array[String] = [
	"You are a worthy opponent, but...",
	"In the end, you will only become a part of my power."
]

var death_line: String = "Damn it! I was so close... So close to breaking free! NO!!"

var boss_card: CardUI
var boss_phase: int = 1
var boss_is_up: bool = false
var phase_two_pending: bool = false
var boss_death_started: bool = false
var player_attack_times: int = 0

var intro_active: bool = true
var is_typing: bool = false
var skip_typing: bool = false
var next_line: bool = false

var dodge_window_open: bool = false
var dodge_used: bool = false
var dodge_active: bool = false
var dodge_tutorial_shown: bool = false
var arm_attack_running: bool = false


func _ready() -> void:
	spawn_player_cards()
	spawn_hand_cards()

	for child in enemy_container.get_children():
		child.queue_free()

	boss_card = card_ui.instantiate()
	enemy_container.add_child(boss_card)
	boss_card.set_card_data(test_boss_data)
	boss_card.is_boss = true
	boss_card.current_health = boss_max_health
	boss_card.health_label.text = str(boss_max_health)
	boss_card.health_changed.connect(update_boss_health)
	boss_card.team = "Enemy"
	boss_card.board_drag_enabled = false
	boss_card.card_visual.hide()

	boss_health_bar.max_value = boss_max_health
	boss_health_bar.value = boss_max_health
	boss_health_bar.show()
	boss_health_bar.modulate.a = 0.0

	$StartBattleButton.disabled = true
	for child in player_container.get_children():
		if child is CardUI:
			child.board_drag_enabled = false

	attack_events.connect("dodge_time", _on_dodge_time)
	attack_events.connect("impact", _on_boss_impact)
	dodge_hint.connect("confirmed", _try_dodge)

	await play_boss_intro()


func fade_screen(to_black: bool, duration: float) -> void:
	var target_alpha: float = 1.0 if to_black else 0.0
	var tween: Tween = create_tween()
	tween.tween_property(fade, "modulate:a", target_alpha, duration)
	await tween.finished


func type_dialogue(line: String) -> void:
	is_typing = true
	skip_typing = false
	next_line = false

	dialogue_text.text = line
	dialogue_text.visible_characters = 0

	for i in range(line.length()):
		if skip_typing:
			break
		dialogue_text.visible_characters = i + 1
		await get_tree().create_timer(0.04).timeout

	dialogue_text.visible_characters = -1
	is_typing = false

	while not next_line:
		await get_tree().process_frame


func _input(event: InputEvent) -> void:
	if intro_active:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if is_typing:
					skip_typing = true
				else:
					next_line = true
				get_viewport().set_input_as_handled()
		return

	if dodge_window_open and event.is_action_pressed("dodge"):
		_try_dodge()
		get_viewport().set_input_as_handled()


func play_boss_intro() -> void:
	intro_active = true
	intro_root.show()
	dialogue_panel.show()
	fade.modulate.a = 1.0

	for line in opening_lines:
		await type_dialogue(line)

	dialogue_panel.hide()
	await fade_screen(false, 2.0)
	intro_root.hide()

	await play_boss_drop()
	await play_boss_health_appear()

	intro_active = false
	$StartBattleButton.disabled = false
	for child in player_container.get_children():
		if child is CardUI:
			child.board_drag_enabled = true


func _on_hand_card_clicked(card: CardUI) -> void:
	if intro_active:
		return
	super._on_hand_card_clicked(card)


func _on_board_card_clicked(card: CardUI) -> void:
	if intro_active:
		return
	super._on_board_card_clicked(card)


func play_boss_drop() -> void:
	var anim: AnimationPlayer = boss_card.animation_player
	anim.play("boss_drop")
	anim.advance(0)
	boss_card.card_visual.show()
	await anim.animation_finished


func play_boss_health_appear() -> void:
	attack_anim.play("health_appear")
	await attack_anim.animation_finished


func play_boss_up() -> void:
	var anim: AnimationPlayer = boss_card.animation_player
	anim.play("boss_up")
	await anim.animation_finished


func play_boss_down() -> void:
	var anim: AnimationPlayer = boss_card.animation_player
	anim.play("boss_drop")
	await anim.animation_finished


func update_boss_health() -> void:
	boss_health_bar.value = boss_card.current_health
	if boss_phase == 1 and not phase_two_pending:
		if boss_card.current_health > 0 and boss_card.current_health <= boss_max_health * 0.5:
			phase_two_pending = true


func attack(attacker: CardUI, target: CardUI) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	if attacker == boss_card:
		if boss_is_up:
			return

		var available_attacks: Array[String] = [
			"Left_Arm_Attack",
			"Fat_Rat_Attack"
		]

		if boss_phase == 2:
			if attack_anim.has_animation("Many_Rat_Attack(Right)"):
				available_attacks.append("Many_Rat_Attack(Right)")
			if attack_anim.has_animation("Right_Arm_Attack"):
				available_attacks.append("Right_Arm_Attack")

		var selected_attack: String = available_attacks.pick_random()

		# Choose direction only after choosing Many Rat as the attack type.
		if selected_attack == "Many_Rat_Attack(Right)":
			if attack_anim.has_animation("Many_Rat_Attack(Left)"):
				if randi_range(0, 1) == 1:
					selected_attack = "Many_Rat_Attack(Left)"

		await perform_boss_attack(selected_attack)
		return

	await super.attack(attacker, target)

	if is_instance_valid(boss_card) and boss_card.is_dead() and not boss_death_started:
		await play_boss_death()
		return

	if not is_instance_valid(attacker) or attacker.team != "Player":
		return

	if boss_is_up:
		super.cleanup_dead_cards()
		if count_living_summons() == 0:
			if not enemy_cards.has(boss_card):
				enemy_cards.append(boss_card)
			boss_card.show()
			await play_boss_down()
			boss_is_up = false
			player_attack_times = 0
			if phase_two_pending:
				await enter_phase_two()
		return

	if phase_two_pending:
		await enter_phase_two()
		return

	player_attack_times += 1
	if player_attack_times >= 2:
		if is_instance_valid(boss_card) and not boss_card.is_dead():
			player_attack_times = 0
			boss_is_up = true
			await play_boss_up()
			boss_card.hide()
			enemy_cards.erase(boss_card)
			await summon_first_wave()
			enemy_index = 0

			if count_living_summons() == 0:
				if not enemy_cards.has(boss_card):
					enemy_cards.append(boss_card)
				boss_card.show()
				await play_boss_down()
				boss_is_up = false


func summon_first_wave() -> void:
	var available: Array[card_resource] = []
	for data in two_star_enemies:
		if data != null and data.minon_type != card_resource.type.Rat:
			available.append(data)

	available.shuffle()
	var summon_count: int = min(3, available.size())
	var last_anim: AnimationPlayer = null

	for i in range(summon_count):
		var summoned_card: CardUI = card_ui.instantiate()
		enemy_container.add_child(summoned_card)
		summoned_card.set_card_data(available[i])
		summoned_card.team = "Enemy"
		summoned_card.board_drag_enabled = false
		enemy_container.move_child(summoned_card, 0)
		enemy_cards.insert(0, summoned_card)

		var anim: AnimationPlayer = summoned_card.animation_player
		anim.play("summon_appear")
		anim.advance(0)
		last_anim = anim

	if last_anim != null:
		await last_anim.animation_finished


func count_living_summons() -> int:
	var count: int = 0
	for card in enemy_cards:
		if card == boss_card:
			continue
		if is_instance_valid(card) and not card.is_dead():
			count += 1
	return count


func perform_boss_attack(animation_name: String) -> void:
	if arm_attack_running:
		return
	if not attack_anim.has_animation(animation_name):
		push_error("Missing Boss animation: " + animation_name)
		return

	arm_attack_running = true
	dodge_window_open = true
	dodge_used = false
	dodge_active = false

	attack_anim.play(animation_name)
	await attack_anim.animation_finished

	dodge_window_open = false
	arm_attack_running = false


func _on_dodge_time() -> void:
	if dodge_tutorial_shown or dodge_used:
		return
	dodge_tutorial_shown = true
	dodge_hint.show_hint()


func _try_dodge() -> void:
	if not dodge_window_open or dodge_used:
		return

	dodge_used = true
	dodge_active = true

	for card in player_cards:
		if is_instance_valid(card) and not card.is_dead():
			card.play_dodge_animation()

	await get_tree().create_timer(0.6, false).timeout
	dodge_active = false


func _on_boss_impact(damage: int) -> void:
	dodge_window_open = false
	if dodge_active:
		return

	for card in player_cards.duplicate():
		if is_instance_valid(card) and not card.is_dead():
			card.take_damage(damage)
	cleanup_dead_cards()


func enter_phase_two() -> void:
	if not phase_two_pending or boss_phase == 2:
		return
	if not is_instance_valid(boss_card) or boss_card.is_dead():
		return
	if phase_two_boss_data == null:
		push_error("Phase 2 Boss Data is missing!")
		return

	var anim: AnimationPlayer = boss_card.animation_player
	if not anim.has_animation("Phase_2_Transform"):
		push_error("Phase_2_Transform is missing!")
		return
	if not anim.has_animation("Phase_2_Reveal"):
		push_error("Phase_2_Reveal is missing!")
		return

	phase_two_pending = false
	boss_phase = 2
	player_attack_times = 0
	intro_active = true
	dodge_window_open = false

	var start_button = $StartBattleButton
	var old_button_disabled: bool = start_button.disabled
	start_button.disabled = true

	var drag_states: Dictionary = {}
	for card in player_container.get_children():
		if card is CardUI:
			drag_states[card] = card.board_drag_enabled
			card.board_drag_enabled = false

	intro_root.show()
	dialogue_panel.show()
	fade.modulate.a = 0.0
	await type_dialogue(phase_two_lines[0])
	dialogue_panel.hide()

	var dark_tween: Tween = create_tween()

	anim.play("Phase_2_Transform")
	await anim.animation_finished

	var saved_hp: int = boss_card.current_health
	boss_card.set_card_data(phase_two_boss_data)
	boss_card.current_health = saved_hp
	boss_card.health_label.text = str(saved_hp)
	boss_card.is_boss = true
	boss_card.team = "Enemy"
	boss_card.board_drag_enabled = false
	update_boss_health()

	anim.play("Phase_2_Reveal")
	await anim.animation_finished
	await fade_screen(false, 0.6)

	dialogue_panel.show()
	await type_dialogue(phase_two_lines[1])
	dialogue_panel.hide()
	intro_root.hide()

	intro_active = false
	start_button.disabled = old_button_disabled
	for card in drag_states:
		if is_instance_valid(card):
			card.board_drag_enabled = drag_states[card]



func play_boss_death() -> void:
	if boss_death_started:
		return

	if not is_instance_valid(boss_card):
		return

	var anim: AnimationPlayer = boss_card.animation_player
	# Show Boss above all Player cards
	boss_card.z_index = 100
	
	if not anim.has_animation("Boss_Dead_Glow"):
		push_error("Boss_Dead_Glow is missing!")
		return

	if not anim.has_animation("Boss_Dead_Disapper"):
		push_error("Boss_Dead_Disapper is missing!")
		return

	boss_death_started = true

	# Lock player actions
	intro_active = true
	dodge_window_open = false
	$StartBattleButton.disabled = true

	# Show dialogue
	intro_root.show()
	dialogue_panel.show()
	fade.modulate.a = 0.0

	# Loop glow animation while dialogue is active
	anim.play("Boss_Dead_Glow")

	# Wait until the player confirms the dialogue
	await type_dialogue(death_line)

	# Hide dialogue and switch to disappearing animation
	dialogue_panel.hide()

	anim.play("Boss_Dead_Disapper")
	await anim.animation_finished

	intro_root.hide()



# Boss battles award a fixed 5 coins, independently of generic enemy-cost bonuses.
func start_combat() -> void:
	attack_count = 0
	player_index = 0
	enemy_index = 0

	while not player_cards.is_empty() and not enemy_cards.is_empty():
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
		GameState.win_count += 1
		GameState.currency += boss_reward_coins
		return_surviving_cards_to_hand()
		reward_screen.show_success(boss_reward_coins)
	elif player_cards.is_empty():
		return_surviving_cards_to_hand()
		GameState.returned_from_failure_or_load = true
		reward_screen.show_failure()
