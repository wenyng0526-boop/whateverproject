extends Control

@export var black_overlay: ColorRect
@export var logo: CanvasItem

@export var logo_fade_duration: float = 3


func _ready() -> void:
	# Start with a completely black screen.
	if black_overlay:
		black_overlay.color = Color.BLACK
		black_overlay.modulate.a = 1.0
		black_overlay.show()

	# Keep the logo and menu hidden.
	if logo:
		logo.modulate.a = 0.0

	# Play the intro.
	await play_intro_fade()


func play_intro_fade() -> void:

	# 2. Fade in the logo.
	if logo:
		var logo_tween := create_tween()
		logo_tween.set_trans(Tween.TRANS_SINE)
		logo_tween.set_ease(Tween.EASE_IN_OUT)

		logo_tween.tween_property(
			logo,
			"modulate:a",
			1.0,
			logo_fade_duration
		)

		await logo_tween.finished

	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
