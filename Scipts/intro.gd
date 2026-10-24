extends Control

@export var black_overlay: ColorRect
@export var logo: CanvasItem
@export var background: Control

@export var black_fade_duration: float = 1.0
@export var logo_fade_duration: float = 1.5
@export var delay: float = 0.5
@export var background_fade_duration: float = 1.0

func _ready() -> void:
	# Start with a completely black screen.
	if black_overlay:
		black_overlay.color = Color.BLACK
		black_overlay.modulate.a = 1.0
		black_overlay.show()

	# Keep the logo and menu hidden.
	if logo:
		logo.modulate.a = 0.0

	if background:
		background.modulate.a = 0.0

	# Play the intro.
	await play_intro_fade()


func play_intro_fade() -> void:
	# 1. Fade away the black overlay.
	if black_overlay:
		var black_tween := create_tween()
		black_tween.set_trans(Tween.TRANS_SINE)
		black_tween.set_ease(Tween.EASE_IN_OUT)

		black_tween.tween_property(
			black_overlay,
			"modulate:a",
			0.0,
			black_fade_duration
		)

		await black_tween.finished
		black_overlay.hide()

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

	# 3. Pause to let the logo stand out.
	await get_tree().create_timer(delay).timeout

	# 4. Fade in the rest of the menu.
	if background:
		var background_tween := create_tween()
		background_tween.set_trans(Tween.TRANS_SINE)
		background_tween.set_ease(Tween.EASE_IN_OUT)

		background_tween.tween_property(
			background,
			"modulate:a",
			1.0,
			background_fade_duration
		)

		await background_tween.finished
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
