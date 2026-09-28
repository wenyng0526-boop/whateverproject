extends PanelContainer

@export var amount_label: Label

func _ready() -> void:
	GameState.currency_changed.connect(_update)
	_update(GameState.currency)

func _update(amount: int) -> void:
	amount_label.text = str(amount)
