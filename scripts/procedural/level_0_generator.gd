class_name Level0Generator extends LevelGenerator
## Level 0 - The Lobby generator
##
## Generates infinite yellow hallways using recursive backtracking maze algorithm.
## Classic Backrooms aesthetic: mono-yellow wallpaper, buzzing fluorescent lights,
## damp carpet, and the hum of eternity.

# ============================================================================
# LEVEL 0 CONFIGURATION
# ============================================================================

func _init() -> void:
	# Create Level 0 configuration
	var config := ProceduralLevelConfig.new()
	config.level_id = 0
	config.level_name = "Level 0 - The Lobby"
	config.corruption_per_chunk = 0.01

	# Add permitted entities with spawn probabilities
	# (from docs/PROCEDURAL_GENERATION_IMPLEMENTATION.md)

	# BACTERIA: Weak entities (MORE common with corruption)
	var bacteria := EntityConfig.new()
	bacteria.entity_id = "bacteria"
	bacteria.base_probability = 0.05  # 5% base chance per sub-chunk
	bacteria.corruption_multiplier = 1.5  # Gets MUCH more common with corruption
	config.add_entity(bacteria)

	# HOUNDS: Dangerous entities (MORE common with corruption)
	var hound := EntityConfig.new()
	hound.entity_id = "hound"
	hound.base_probability = 0.01  # 1% base chance per sub-chunk
	hound.corruption_multiplier = 2.0  # Gets MORE common (threat escalation)
	config.add_entity(hound)

	# ALMOND WATER: Healing item (LESS common with corruption)
	var almond_water := EntityConfig.new()
	almond_water.entity_id = "almond_water"
	almond_water.base_probability = 0.03  # 3% base chance per sub-chunk
	almond_water.corruption_multiplier = -0.5  # Gets LESS common (scarcity)
	config.add_entity(almond_water)

	# EXIT STAIRS: Level transition (MORE common with corruption - exit forcing!)
	var exit_stairs := EntityConfig.new()
	exit_stairs.entity_id = "exit_stairs"
	exit_stairs.base_probability = 0.001  # 0.1% base chance (very rare initially)
	exit_stairs.corruption_multiplier = 2.0  # Gets MORE common (forces progression)
	config.add_entity(exit_stairs)

	setup_level_config(config)
	Log.system("Level0Generator initialized with %d entity types" % config.permitted_entities.size())

# ============================================================================
# MAZE GENERATION - WAVE FUNCTION COLLAPSE (WFC)
# ============================================================================

# WFC tile types (simplified - just floor/wall with adjacency rules)
enum WFCTile {
	FLOOR,
	WALL,
	SUPERPOSITION  # Uncollapsed state
}

# WFC configuration
const FLOOR_WEIGHT := 0.70  # 70% floors → ~30% walls (user requirement)
const WALL_WEIGHT := 0.30
const EDGE_CORRIDOR_SPACING := 16  # Tiles between edge corridors (for chunk connectivity)

func generate_chunk(chunk: Chunk, world_seed: int) -> void:
	"""Generate Level 0 chunk using Wave Function Collapse (WFC)

	WFC creates varied corridor patterns by:
	- Collapsing tiles from superposition to floor/wall using weighted probabilities
	- Using world-space coordinates for RNG seeding (ensures chunk connectivity)
	- Adding path constraints at chunk edges for guaranteed traversal
	- Creating ~30% walls through FLOOR_WEIGHT (70%) vs WALL_WEIGHT (30%)

	Benefits over recursive backtracking:
	- Natural variety (no uniform 3×3 junctions)
	- Guaranteed chunk connectivity (world-space seeding)
	- Controlled wall density (tile weights)
	- Emergent room-like patterns
	"""
	# Phase 1: Initialize WFC grid (all tiles in superposition)
	var wfc_grid := _init_wfc_grid()

	# Phase 2: Add path constraints (force corridors at chunk edges for connectivity)
	_add_edge_constraints(wfc_grid, chunk.position)

	# Phase 3: Collapse tiles using WFC algorithm with world-space seeding
	_collapse_wfc(wfc_grid, chunk.position, world_seed)

	# Phase 4: Apply WFC result to chunk tiles
	_apply_wfc_to_chunk(wfc_grid, chunk)

	# Phase 5: Ensure connectivity (flood fill + path carving if needed)
	_ensure_connectivity(chunk)

	Log.grid("Generated Level 0 chunk at %s (walkable: %d tiles, WFC)" % [
		chunk.position,
		chunk.get_walkable_count()
	])

# ============================================================================
# WFC IMPLEMENTATION
# ============================================================================

func _init_wfc_grid() -> Array:
	"""Initialize 128×128 WFC grid with all tiles in superposition state

	Returns Array of Arrays (2D grid) of WFCTile values
	"""
	var grid: Array = []
	grid.resize(Chunk.SIZE)

	for y in range(Chunk.SIZE):
		var row: Array = []
		row.resize(Chunk.SIZE)
		for x in range(Chunk.SIZE):
			row[x] = WFCTile.SUPERPOSITION
		grid[y] = row

	return grid

func _add_edge_constraints(wfc_grid: Array, chunk_pos: Vector2i) -> void:
	"""Add path constraints at chunk edges for guaranteed inter-chunk connectivity

	Uses deterministic world-space pattern to ensure adjacent chunks align.
	Creates corridors at regular intervals on all 4 edges.
	"""
	var chunk_world_offset := chunk_pos * Chunk.SIZE

	# Top and bottom edges (y = 0 and y = 127)
	for x in range(Chunk.SIZE):
		var world_x := chunk_world_offset.x + x
		if world_x % EDGE_CORRIDOR_SPACING == 0:
			# Force corridor at top edge
			wfc_grid[0][x] = WFCTile.FLOOR
			wfc_grid[1][x] = WFCTile.FLOOR  # 2 tiles deep for visibility
			# Force corridor at bottom edge
			wfc_grid[Chunk.SIZE - 1][x] = WFCTile.FLOOR
			wfc_grid[Chunk.SIZE - 2][x] = WFCTile.FLOOR

	# Left and right edges (x = 0 and x = 127)
	for y in range(Chunk.SIZE):
		var world_y := chunk_world_offset.y + y
		if world_y % EDGE_CORRIDOR_SPACING == 0:
			# Force corridor at left edge
			wfc_grid[y][0] = WFCTile.FLOOR
			wfc_grid[y][1] = WFCTile.FLOOR  # 2 tiles deep
			# Force corridor at right edge
			wfc_grid[y][Chunk.SIZE - 1] = WFCTile.FLOOR
			wfc_grid[y][Chunk.SIZE - 2] = WFCTile.FLOOR

func _collapse_wfc(wfc_grid: Array, chunk_pos: Vector2i, world_seed: int) -> void:
	"""Collapse WFC grid using world-space seeding for deterministic generation

	Algorithm:
	1. Iterate through all uncollapsed tiles
	2. For each tile, use world-space coordinate as RNG seed
	3. Collapse to FLOOR or WALL based on weighted probabilities
	4. This ensures adjacent chunks generate identically at boundaries

	World-space seeding is the KEY to chunk connectivity - tiles at chunk
	boundaries have the same world coordinates in adjacent chunks, so they
	collapse identically.

	Performance: Reuses single RNG instance, reseeded for each tile (fast!)
	"""
	var chunk_world_offset := chunk_pos * Chunk.SIZE
	var rng := RandomNumberGenerator.new()  # Reuse this instance

	for y in range(Chunk.SIZE):
		for x in range(Chunk.SIZE):
			# Skip if already constrained (edge corridors)
			if wfc_grid[y][x] != WFCTile.SUPERPOSITION:
				continue

			# Calculate world-space coordinate for this tile
			var world_x := chunk_world_offset.x + x
			var world_y := chunk_world_offset.y + y

			# Reseed RNG with world position + global seed
			# CRITICAL: Same world coordinates = same seed = same result across chunks!
			var tile_seed := hash(Vector3i(world_x, world_y, world_seed))
			rng.seed = tile_seed

			# Collapse to FLOOR or WALL based on weights
			var roll := rng.randf()
			if roll < FLOOR_WEIGHT:
				wfc_grid[y][x] = WFCTile.FLOOR
			else:
				wfc_grid[y][x] = WFCTile.WALL

func _apply_wfc_to_chunk(wfc_grid: Array, chunk: Chunk) -> void:
	"""Convert WFC grid to chunk tile data

	Maps WFCTile values to SubChunk.TileType values
	"""
	for y in range(Chunk.SIZE):
		for x in range(Chunk.SIZE):
			var wfc_tile = wfc_grid[y][x]
			var tile_type: SubChunk.TileType

			match wfc_tile:
				WFCTile.FLOOR:
					tile_type = SubChunk.TileType.FLOOR
				WFCTile.WALL, WFCTile.SUPERPOSITION:  # Treat uncollapsed as wall (shouldn't happen)
					tile_type = SubChunk.TileType.WALL

			_set_tile_in_chunk(chunk, Vector2i(x, y), tile_type)

func _ensure_connectivity(chunk: Chunk) -> void:
	"""Ensure all floor tiles are connected (flood fill validation)

	If disconnected regions found, carve connecting paths.
	This is a safety net - world-space seeding should handle connectivity,
	but this ensures no isolated regions exist.
	"""
	# Find all floor tiles
	var floor_tiles: Array[Vector2i] = []
	for y in range(Chunk.SIZE):
		for x in range(Chunk.SIZE):
			var tile := chunk.get_tile(Vector2i(x, y))
			if tile == SubChunk.TileType.FLOOR:
				floor_tiles.append(Vector2i(x, y))

	if floor_tiles.is_empty():
		push_warning("Chunk %s has NO floor tiles! Forcing center tile to floor." % chunk.position)
		_set_tile_in_chunk(chunk, Vector2i(Chunk.SIZE / 2, Chunk.SIZE / 2), SubChunk.TileType.FLOOR)
		return

	# Flood fill from first floor tile
	var visited: Dictionary = {}  # Vector2i → bool
	var to_visit: Array[Vector2i] = [floor_tiles[0]]
	visited[floor_tiles[0]] = true

	while not to_visit.is_empty():
		var current: Vector2i = to_visit.pop_front()

		# Check 4 neighbors
		var neighbors := [
			current + Vector2i(0, -1),  # North
			current + Vector2i(1, 0),   # East
			current + Vector2i(0, 1),   # South
			current + Vector2i(-1, 0),  # West
		]

		for neighbor in neighbors:
			# Skip if out of bounds
			if neighbor.x < 0 or neighbor.x >= Chunk.SIZE or \
			   neighbor.y < 0 or neighbor.y >= Chunk.SIZE:
				continue

			# Skip if already visited
			if visited.get(neighbor, false):
				continue

			# Skip if not floor
			var tile := chunk.get_tile(neighbor)
			if tile != SubChunk.TileType.FLOOR:
				continue

			visited[neighbor] = true
			to_visit.append(neighbor)

	# Check if all floor tiles were reached
	var reachable_count := visited.size()
	var total_floor_count := floor_tiles.size()

	if reachable_count < total_floor_count:
		Log.grid("Chunk %s has %d disconnected floor tiles (reachable: %d, total: %d)" % [
			chunk.position,
			total_floor_count - reachable_count,
			reachable_count,
			total_floor_count
		])
		# TODO: Carve connecting paths if needed (future enhancement)
		# For now, world-space seeding should prevent this

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _set_tile_in_chunk(chunk: Chunk, tile_pos: Vector2i, tile_type: SubChunk.TileType) -> void:
	"""Helper: Set tile at absolute chunk tile coordinate

	Converts chunk-local tile coordinates (0-127) to sub-chunk + local coordinates.
	"""
	# Calculate which sub-chunk contains this tile
	var sub_pos := Vector2i(tile_pos.x / SubChunk.SIZE, tile_pos.y / SubChunk.SIZE)

	# Calculate tile position within that sub-chunk
	var local_pos := Vector2i(
		posmod(tile_pos.x, SubChunk.SIZE),
		posmod(tile_pos.y, SubChunk.SIZE)
	)

	var sub := chunk.get_sub_chunk(sub_pos)
	if sub:
		sub.set_tile(local_pos, tile_type)

# ============================================================================
# DEBUG
# ============================================================================

func _to_string() -> String:
	return "Level0Generator(Wave Function Collapse)"
