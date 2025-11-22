extends Control
## Minimap - Top-down view of explored areas
##
## Features:
## - 512x512 pixel map (1 pixel = 1 tile)
## - Rotates to match camera direction (forward = north)
## - Shows walkable/walls, player position, player trail
## - Chunk boundaries visible
## - Colorblind-safe palette

# ============================================================================
# CONSTANTS
# ============================================================================

const MAP_SIZE := 256  # Pixels (image size)
const TRAIL_LENGTH := 10000  # Steps to remember

## Colorblind-safe colors (light floor, dark walls)
const COLOR_WALKABLE := Color("#8a8a8a")  # Light gray
const COLOR_WALL := Color("#1a3a52")  # Dark blue-gray
const COLOR_PLAYER := Color("#00d9ff")  # Bright cyan
const COLOR_TRAIL_START := Color(0.0, 0.85, 1.0, 0.3)  # Faint cyan
const COLOR_TRAIL_END := Color(0.0, 0.85, 1.0, 1.0)  # Bright cyan
const COLOR_CHUNK_BOUNDARY := Color("#404040")  # Subtle gray
const COLOR_UNLOADED := Color("#000000")  # Black

# ============================================================================
# NODES
# ============================================================================

@onready var map_texture_rect: TextureRect = $MapTextureRect

# ============================================================================
# STATE
# ============================================================================

## Dynamic image for minimap rendering
var map_image: Image

## Texture displayed on screen
var map_texture: ImageTexture

## Player position trail (ring buffer)
var player_trail: Array[Vector2i] = []
var trail_index: int = 0

## Reference to grid for tile data
var grid: Node = null

## Reference to player for position/camera
var player: Node = null

## Camera rotation (for north orientation)
var camera_rotation: float = 0.0
var last_camera_rotation: float = 0.0

## Dirty flag - needs content redraw
var content_dirty: bool = true

## Walkability cache for performance (cleared when chunks change)
var walkability_cache: Dictionary = {}  # Vector2i -> bool

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Create image and texture
	map_image = Image.create(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RGBA8)
	map_texture = ImageTexture.create_from_image(map_image)
	map_texture_rect.texture = map_texture

	# Initialize trail buffer
	player_trail.resize(TRAIL_LENGTH)
	for i in range(TRAIL_LENGTH):
		player_trail[i] = Vector2i(-99999, -99999)  # Invalid position

	# Clear cache when initial chunks finish loading
	if ChunkManager:
		ChunkManager.initial_load_completed.connect(_on_initial_load_completed)

	Log.system("Minimap initialized (%dx%d)" % [MAP_SIZE, MAP_SIZE])
	Log.system("Minimap TextureRect: %s" % map_texture_rect)

func _process(_delta: float) -> void:
	# Update camera rotation every frame (for north orientation)
	if player:
		var camera_rig = player.get_node_or_null("CameraRig")
		if camera_rig:
			var h_pivot = camera_rig.get_node_or_null("HorizontalPivot")
			if h_pivot:
				camera_rotation = h_pivot.rotation.y

				# Rotate the texture rect itself instead of re-rendering pixels
				# Much faster - just a transform, not 65k pixel operations
				map_texture_rect.rotation = camera_rotation

	# Only redraw content when it actually changes (on turn, chunk load, etc)
	if content_dirty:
		_render_map()
		content_dirty = false

# ============================================================================
# PUBLIC API
# ============================================================================

func set_grid(grid_ref: Node) -> void:
	"""Set grid reference for tile queries"""
	grid = grid_ref
	content_dirty = true

func set_player(player_ref: Node) -> void:
	"""Set player reference for position/camera"""
	player = player_ref

func on_player_moved(new_position: Vector2i) -> void:
	"""Called when player moves - update trail and mark dirty"""
	# Add to trail (ring buffer)
	player_trail[trail_index] = new_position
	trail_index = (trail_index + 1) % TRAIL_LENGTH

	content_dirty = true

func on_chunk_loaded(_chunk_pos: Vector2i) -> void:
	"""Called when chunk loads - mark dirty and clear cache"""
	walkability_cache.clear()
	content_dirty = true

func on_chunk_unloaded(_chunk_pos: Vector2i) -> void:
	"""Called when chunk unloads - mark dirty and clear cache"""
	walkability_cache.clear()
	content_dirty = true

func _on_initial_load_completed() -> void:
	"""Called when ChunkManager finishes initial chunk loading"""
	# Clear cache to remove any placeholder/empty chunk data
	walkability_cache.clear()
	content_dirty = true
	Log.system("Minimap cache cleared after initial chunk load")

# ============================================================================
# RENDERING
# ============================================================================

func _render_map() -> void:
	"""Render entire minimap (called on turn)"""
	if not grid or not player:
		return

	# Clear to unloaded color
	map_image.fill(COLOR_UNLOADED)

	# Get player position for centering
	var player_pos: Vector2i = player.grid_position

	# Calculate visible area (centered on player) - full 256×256 tile area
	var half_size := MAP_SIZE / 2
	var min_tile := player_pos - Vector2i(half_size, half_size)
	var max_tile := player_pos + Vector2i(half_size, half_size)

	# Render tiles
	var tiles_rendered := 0
	for y in range(min_tile.y, max_tile.y):
		for x in range(min_tile.x, max_tile.x):
			var tile_pos := Vector2i(x, y)
			var screen_pos := _world_to_screen(tile_pos, player_pos)

			if not _is_valid_screen_pos(screen_pos):
				continue

			# Check if tile is loaded
			if not grid.has_method("is_walkable"):
				continue

			# Get tile type (walkable vs wall) - use cache for performance
			var is_walkable: bool
			if walkability_cache.has(tile_pos):
				is_walkable = walkability_cache[tile_pos]
			else:
				is_walkable = grid.is_walkable(tile_pos)
				walkability_cache[tile_pos] = is_walkable

			var color := COLOR_WALL if not is_walkable else COLOR_WALKABLE

			# Draw directly without rotation (TextureRect handles rotation now)
			if _is_valid_screen_pos(screen_pos):
				map_image.set_pixelv(screen_pos, color)
				tiles_rendered += 1

	# Log if no tiles were rendered (indicates a problem)
	if tiles_rendered == 0:
		Log.warn(Log.Category.SYSTEM, "Minimap rendered 0 tiles! Player at %s, visible area: %s to %s" % [player_pos, min_tile, max_tile])

	# Draw player trail
	_draw_trail(player_pos)

	# Draw player position (centered - no rotation needed, TextureRect rotates)
	var player_screen := _world_to_screen(player_pos, player_pos)
	if _is_valid_screen_pos(player_screen):
		# Draw 3x3 player marker
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var pixel := player_screen + Vector2i(dx, dy)
				if _is_valid_screen_pos(pixel):
					map_image.set_pixelv(pixel, COLOR_PLAYER)

	# Update texture
	map_texture.update(map_image)

func _draw_chunk_boundaries(player_pos: Vector2i) -> void:
	"""Draw chunk boundary lines (every 128 tiles)"""
	const CHUNK_SIZE := 128
	var half_size := MAP_SIZE / 2
	var min_tile := player_pos - Vector2i(half_size, half_size)
	var max_tile := player_pos + Vector2i(half_size, half_size)

	# Find chunk boundaries in visible area
	var min_chunk := Vector2i(floor(float(min_tile.x) / CHUNK_SIZE), floor(float(min_tile.y) / CHUNK_SIZE))
	var max_chunk := Vector2i(ceil(float(max_tile.x) / CHUNK_SIZE), ceil(float(max_tile.y) / CHUNK_SIZE))

	# Draw vertical lines (no rotation - TextureRect handles it)
	for chunk_x in range(min_chunk.x, max_chunk.x + 1):
		var world_x := chunk_x * CHUNK_SIZE
		for y in range(min_tile.y, max_tile.y):
			var tile_pos := Vector2i(world_x, y)
			var screen_pos := _world_to_screen(tile_pos, player_pos)

			if _is_valid_screen_pos(screen_pos):
				map_image.set_pixelv(screen_pos, COLOR_CHUNK_BOUNDARY)

	# Draw horizontal lines (no rotation - TextureRect handles it)
	for chunk_y in range(min_chunk.y, max_chunk.y + 1):
		var world_y := chunk_y * CHUNK_SIZE
		for x in range(min_tile.x, max_tile.x):
			var tile_pos := Vector2i(x, world_y)
			var screen_pos := _world_to_screen(tile_pos, player_pos)

			if _is_valid_screen_pos(screen_pos):
				map_image.set_pixelv(screen_pos, COLOR_CHUNK_BOUNDARY)

func _draw_trail(player_pos: Vector2i) -> void:
	"""Draw player movement trail with fading"""
	var valid_trail_count := 0

	# Count valid trail positions
	for pos in player_trail:
		if pos.x != -99999:
			valid_trail_count += 1

	if valid_trail_count == 0:
		return

	# Draw trail with gradient (oldest = faint, newest = bright)
	for i in range(TRAIL_LENGTH):
		var trail_pos: Vector2i = player_trail[i]

		if trail_pos.x == -99999:
			continue  # Invalid position

		# Calculate age (0.0 = oldest, 1.0 = newest)
		var age := float(i) / float(valid_trail_count)
		var color := COLOR_TRAIL_START.lerp(COLOR_TRAIL_END, age)

		var screen_pos := _world_to_screen(trail_pos, player_pos)

		if _is_valid_screen_pos(screen_pos):
			map_image.set_pixelv(screen_pos, color)

# ============================================================================
# HELPERS
# ============================================================================

func _world_to_screen(world_pos: Vector2i, player_pos: Vector2i) -> Vector2i:
	"""Convert world tile position to screen pixel (before rotation)"""
	var half_size := MAP_SIZE / 2
	var relative := world_pos - player_pos
	return Vector2i(half_size + relative.x, half_size + relative.y)

func _rotate_screen_pos(screen_pos: Vector2i, angle: float) -> Vector2i:
	"""Rotate screen position around center by angle (radians)"""
	var center := Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	var offset := Vector2(screen_pos) - center

	# Rotate by camera angle
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	var rotated := Vector2(
		offset.x * cos_a - offset.y * sin_a,
		offset.x * sin_a + offset.y * cos_a
	)

	var final_pos := center + rotated
	return Vector2i(int(final_pos.x), int(final_pos.y))

func _is_valid_screen_pos(pos: Vector2i) -> bool:
	"""Check if screen position is within bounds"""
	return pos.x >= 0 and pos.x < MAP_SIZE and pos.y >= 0 and pos.y < MAP_SIZE
