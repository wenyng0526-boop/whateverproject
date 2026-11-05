extends Node2D

signal attack_hit

@onready var rat_claw: Sprite2D = $RatAttack
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func set_target_position(target_position: Vector2) -> void:
	rat_claw.global_position = target_position


func play_effect(minon_type, team: String) -> void:
	var animation_name: String = ""

	match minon_type:
		card_resource.type.Rat:
			if team == "Player":
				animation_name = "attack_anim/rat_attack_player"
			else:
				animation_name = "attack_anim/rat_attack_enemy"

		card_resource.type.Goblin:
			if team == "Player":
				animation_name = "attack_anim/goblin_attack_player"
			else:
				animation_name = "attack_anim/goblin_attack_enemy"

		card_resource.type.Knight:
			if team == "Player":
				animation_name = "attack_anim/knight_attack_player"
			else:
				animation_name = "attack_anim/knight_attack_enemy"

		card_resource.type.Skeleton:
			if team == "Player":
				animation_name = "attack_anim/skeleton_attack_player"
			else:
				animation_name = "attack_anim/skeleton_attack_enemy"

	animation_player.play(animation_name)

	await animation_player.animation_finished
	queue_free()


func trigger_attack_hit() -> void:
	attack_hit.emit()
