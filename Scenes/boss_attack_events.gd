extends Node

signal dodge_time
signal impact(damage: int)


func open_dodge() -> void:
	dodge_time.emit()


func hit(damage: int) -> void:
	impact.emit(damage)
