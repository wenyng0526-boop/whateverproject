extends Node2D

@export var animated_sprite: AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("hit")
	await animated_sprite.animation_finished
	queue_free()
