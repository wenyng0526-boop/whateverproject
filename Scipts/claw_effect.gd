extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func play_effect(minion_type: card_resource.type) -> void:
	match minion_type:
		card_resource.type.Goblin:
			animation_player.play("goblin_attack")

		card_resource.type.Rat:
			animation_player.play("rat_attack")

		card_resource.type.Skeleton:
			animation_player.play("skeleton_attack")

		card_resource.type.Knight:
			animation_player.play("knight_attack")

	await animation_player.animation_finished
	queue_free()
