class_name VendingMachineBehavior extends EntityBehavior
## Vending machine behavior - stationary interactable, does nothing

func reset_turn_state(entity: WorldEntity) -> void:
	entity.moves_remaining = 0

func process_turn(_entity: WorldEntity, _player_pos: Vector2i, _grid) -> void:
	# Vending machines don't move or act
	pass
