class_name ExaminableEnvironmentTile
extends Area3D
## Invisible examination area for environment tiles (walls/floors/ceilings)
##
## Positioned at same world location as GridMap visual tile.
## Contains Examinable component for Look Mode detection.
##
## This is part of the examination overlay system - separate from GridMap rendering.
## GridMap handles visuals, these Area3D nodes handle examination interaction.

@onready var examinable: Examinable = $Examinable

func setup(tile_type: String, entity_id: String, grid_pos: Vector2i, world_pos: Vector3) -> void:
	"""Initialize this examination tile

	Args:
		tile_type: "wall", "floor", or "ceiling"
		entity_id: KnowledgeDB lookup ID (e.g., "level_0_wall")
		grid_pos: Grid coordinates (for debugging/tracking)
		world_pos: 3D world position for placement
	"""
	name = "Exam_%s_%d_%d" % [tile_type, grid_pos.x, grid_pos.y]
	global_position = world_pos

	# Configure Examinable component
	examinable.entity_id = entity_id
	examinable.entity_type = Examinable.EntityType.ENVIRONMENT

	# Collision layer for examination (layer 4 = bit 8)
	# Separate from GridMap movement collision (layer 2)
	collision_layer = 8
	collision_mask = 0

	Log.system("Created examinable tile: %s at %s (grid: %s)" % [entity_id, world_pos, grid_pos])

func _ready() -> void:
	"""Ensure Examinable component exists"""
	if not has_node("Examinable"):
		push_error("ExaminableEnvironmentTile missing Examinable component!")
