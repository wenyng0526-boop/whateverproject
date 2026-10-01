extends Resource

class_name card_resource

@export var name: String
@export var cost: int
@export var attack: int = 1
@export var health: int = 1
@export var image: Texture
@export var minon_type: type
@export var fusion_tier: int = 1 #e.g. current_attack * 2^(fusion tier)

enum type {Goblin, Rat, Skeleton, Knight}
