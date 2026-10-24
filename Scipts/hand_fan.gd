extends HBoxContainer
 
@export var push_distance: float = 80.0
@export_range(0.0,1.0) var falloff: float = 0.5
 
@export var tween_time : float = 0.15
 
@export var max_hand_width:float = 1700
@export var max_separation: float = 4.0
 
@export var fan_angle: float = 2.5
@export var max_fan_angle: float = 12.0
@export var lean_angle: float = 3
## Pixels lower that the END cards sit than the middle of the hand
## (any hand of 3+ cards). 0 = no arc.
@export var arc_drop: float = 30.0
## Also lowers tilted cards so their raised top corner doesn't lift the ends.
@export var compensate_tilt: bool = true
 
var hovered: CardUI = null
var _refresh_queued: bool = false
 
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	_queue_refresh()
 
 
func _on_child_entered(node: Node) -> void:
	var card := node as CardUI
	if card == null:
		return
	card.mouse_entered.connect(_on_card_hovered.bind(card))
	card.mouse_exited.connect(_on_card_unhovered.bind(card))
	_queue_refresh()
 
 
func _on_child_exiting(node: Node) -> void:
	if node == hovered:
		hovered = null
	_queue_refresh()
 
 
func _on_card_hovered(card: CardUI) -> void:
	hovered = card
	_queue_refresh()
 
 
func _on_card_unhovered(card: CardUI) -> void:
	if hovered == card:
		hovered = null
	_queue_refresh()
 
 
# Hovering card A -> card B fires "exit A" then "enter B" in the same frame.
# Deferring and merging the refresh means we only react to the final state.
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh.call_deferred()
 
 
func _refresh() -> void:
	_refresh_queued = false
	_update_separation()
 
	var cards := _get_cards()
	var count: int = cards.size()
	var hovered_index: int = cards.find(hovered)
	var middle: float = (count - 1) / 2.0
 
	for i in count:
		var target_x := 0.0
		# Resting fan: negative on the left, positive (clockwise) on the right.
		var resting_angle := clampf((i - middle) * fan_angle, -max_fan_angle, max_fan_angle)
		var target_angle := resting_angle
		# Arc: parabola, 0 in the middle, arc_drop at the end cards.
		var target_y: float = arc_drop * pow((i - middle) / maxf(middle, 1.0), 2.0)
		if compensate_tilt:
			target_y += _tilt_rise(cards[i], resting_angle)
		# card.gd returns the card to this height after the hover lift.
		cards[i].rest_y = target_y
 
		if hovered_index != -1:
			if i == hovered_index:
				target_angle = 0.0
			else:
				var offset: int = i - hovered_index
				var fade: float = pow(falloff, absi(offset) - 1)
				target_x = signf(offset) * push_distance * fade
				target_angle += signf(offset) * lean_angle * fade
 
		# The hovered card's height is handled by card.gd (the hover lift).
		_move_visual(cards[i], target_x, target_angle, target_y, i != hovered_index)
 
 
func _get_cards() -> Array[CardUI]:
	var cards: Array[CardUI] = []
	for child in get_children():
		var card := child as CardUI
		# spawn_hand_cards()/refresh_hand() queue_free() the old cards, which
		# stay in the tree until the end of the frame, so skip them.
		if card != null and not card.is_queued_for_deletion():
			cards.append(card)
	return cards
 
 
func _move_visual(card: CardUI, target_x: float, target_angle: float, target_y: float, move_y: bool) -> void:
	var visual: Control = card.card_visual
	if visual == null:
		return
 
	if card.has_meta("fan_tween"):
		var old_tween: Tween = card.get_meta("fan_tween")
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
 
	# Rotate around the bottom-centre of the card art, like a hand of cards.
	visual.pivot_offset = _get_pivot(card, visual)
 
	# card.gd tweens "position:y" for the lift; this tweens "position:x" and
	# "rotation", so they don't fight each other.
	var tween := card.create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(visual, "position:x", target_x, tween_time)
	tween.tween_property(visual, "rotation", deg_to_rad(target_angle), tween_time)
	if move_y:
		tween.tween_property(visual, "position:y", target_y, tween_time)
	card.set_meta("fan_tween", tween)
 
 
# How much higher the raised top corner of a card tilted by angle_deg gets
# than the same card flat (the pivot is the bottom-centre of the art).
func _tilt_rise(card: CardUI, angle_deg: float) -> float:
	if card.picture == null:
		return 0.0
	var half_width: float = card.picture.size.x * 0.5
	var art_height: float = card.picture.size.y
	var angle: float = deg_to_rad(absf(angle_deg))
	return maxf(half_width * sin(angle) - art_height * (1.0 - cos(angle)), 0.0)
 
 
func _get_pivot(card: CardUI, visual: Control) -> Vector2:
	var visual_size: Vector2 = visual.size
	if visual_size.x < 1.0:
		visual_size = card.custom_minimum_size
	var art_half_height := 0.0
	if card.picture != null:
		art_half_height = card.picture.size.y * 0.5
	return Vector2(visual_size.x * 0.5, visual_size.y * 0.5 + art_half_height)
 
 
func _update_separation() -> void:
	var cards := _get_cards()
	if cards.size() < 2:
		return
	var card_width: float = cards[0].custom_minimum_size.x
	var needed: float = (max_hand_width - cards.size() * card_width) / (cards.size() - 1)
	add_theme_constant_override("separation", int(minf(needed, max_separation)))
