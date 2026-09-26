extends Node2D

@onready var damage_label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func show_damage(amount: int) -> void:
	damage_label.text = "-" + str(amount)

	animation_player.play("damage")
	await animation_player.animation_finished

	queue_free()
