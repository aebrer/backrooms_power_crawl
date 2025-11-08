class_name Grid3D
extends Node3D
## 3D grid system using GridMap for tile-based world
##
## Maintains same logical grid (Vector2i) as 2D version,
## but renders in 3D space using GridMap.

# Grid configuration
const GRID_SIZE := Vector2i(128, 128)
const CELL_SIZE := Vector3(2.0, 1.0, 2.0)  # X, Y (height), Z - doubled for visibility

# GridMap reference
@onready var grid_map: GridMap = $GridMap

# Grid data (same as 2D version)
var grid_size: Vector2i = GRID_SIZE
var walkable_cells: Array[Vector2i] = []

# MeshLibrary item IDs
enum TileType {
	FLOOR = 0,
	WALL = 1,
	CEILING = 2,
}

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	grid_map.cell_size = CELL_SIZE
	print("[Grid3D] Initialized: %d x %d" % [grid_size.x, grid_size.y])

func initialize(size: Vector2i) -> void:
	"""Initialize grid with given size"""
	grid_size = size
	_generate_grid()

# ============================================================================
# GRID GENERATION
# ============================================================================

func _generate_grid() -> void:
	"""Generate 3D grid using GridMap"""
	# For now, create simple open area with walls around edges
	# TODO: Replace with Backrooms procedural generation

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			var is_edge = x == 0 or x == grid_size.x - 1 or y == 0 or y == grid_size.y - 1

			if is_edge:
				# Place wall
				grid_map.set_cell_item(Vector3i(x, 0, y), TileType.WALL)
			else:
				# Place floor
				grid_map.set_cell_item(Vector3i(x, 0, y), TileType.FLOOR)
				walkable_cells.append(pos)

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	"""Convert 2D grid coordinates to 3D world position"""
	# Use GridMap's built-in conversion
	var cell_3d = Vector3i(grid_pos.x, 0, grid_pos.y)
	return grid_map.map_to_local(cell_3d)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	"""Convert 3D world position to 2D grid coordinates"""
	var cell_3d = grid_map.local_to_map(world_pos)
	return Vector2i(cell_3d.x, cell_3d.z)

# ============================================================================
# GRID QUERIES (Same API as 2D version)
# ============================================================================

func is_walkable(pos: Vector2i) -> bool:
	"""Check if grid position is walkable"""
	if not is_in_bounds(pos):
		return false

	var cell_item = grid_map.get_cell_item(Vector3i(pos.x, 0, pos.y))
	return cell_item == TileType.FLOOR

func is_in_bounds(pos: Vector2i) -> bool:
	"""Check if position is within grid bounds"""
	return pos.x >= 0 and pos.x < grid_size.x and \
	       pos.y >= 0 and pos.y < grid_size.y

func get_random_walkable_position() -> Vector2i:
	"""Get random walkable position"""
	if walkable_cells.is_empty():
		return Vector2i(grid_size.x / 2, grid_size.y / 2)
	return walkable_cells.pick_random()
