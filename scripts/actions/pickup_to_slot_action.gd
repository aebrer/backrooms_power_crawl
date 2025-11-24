class_name PickupToSlotAction extends Action
## Action for equipping a picked-up item to a specific slot
##
## This action is queued after the player selects a slot in the pickup UI.
## It handles equipping to empty slots, leveling up duplicates, or overwriting.

var item: Item  ## The item being picked up
var pool_type: Item.PoolType  ## Which pool (BODY/MIND/NULL/LIGHT)
var slot_index: int  ## Target slot (0-N)
var action_type: int  ## ActionType enum value (equip/combine/overwrite)
var world_position: Vector2i  ## Item's world position (for removal)

func _init(picked_item: Item, target_pool: Item.PoolType, target_slot: int, type: int, pos: Vector2i):
	"""Initialize pickup to slot action

	Args:
		picked_item: Item resource to equip
		target_pool: Pool type (BODY/MIND/NULL/LIGHT)
		target_slot: Slot index (0-N)
		type: ActionType (EQUIP_EMPTY, COMBINE_LEVEL_UP, OVERWRITE)
		pos: World position of item
	"""
	item = picked_item
	pool_type = target_pool
	slot_index = target_slot
	action_type = type
	world_position = pos

func can_execute(player: Player3D) -> bool:
	"""Check if pickup to slot is valid

	Returns:
		true if player has the pool and slot is valid
	"""
	if not player:
		return false

	var pool = _get_pool(player)
	if not pool:
		return false

	if slot_index < 0 or slot_index >= pool.max_slots:
		return false

	return true

func execute(player: Player3D) -> void:
	"""Execute pickup to slot

	This performs the actual equip/level-up/overwrite and removes the item from the world.
	"""
	if not can_execute(player):
		Log.warn(Log.Category.ACTION, "Cannot execute pickup to slot")
		return

	var pool = _get_pool(player)
	if not pool:
		return

	# Perform the appropriate action
	match action_type:
		0:  # EQUIP_EMPTY
			pool.add_item(item, slot_index, player)
			Log.player("Equipped %s to slot %d" % [item.item_name, slot_index + 1])

		1:  # COMBINE_LEVEL_UP
			var existing_item = pool.get_item(slot_index)
			if existing_item:
				existing_item.level_up()
				pool.emit_signal("item_leveled_up", existing_item, slot_index, existing_item.level)

				# Re-apply stat bonus
				existing_item._remove_stat_bonus(player)
				existing_item._apply_stat_bonus(player)

				Log.player("Combined %s - leveled up to Level %d!" % [item.item_name, existing_item.level])

		2:  # OVERWRITE
			pool.overwrite_item(slot_index, item, player)
			Log.player("Equipped %s to slot %d (overwriting previous item)" % [item.item_name, slot_index + 1])

	# Remove item from world
	_remove_item_from_world(player)

	# Increment turn count (this is a turn action)
	player.turn_count += 1

func _get_pool(player: Player3D) -> ItemPool:
	"""Get the appropriate ItemPool for this action

	Args:
		player: Player reference

	Returns:
		ItemPool or null if invalid type
	"""
	match pool_type:
		Item.PoolType.BODY:
			return player.body_pool
		Item.PoolType.MIND:
			return player.mind_pool
		Item.PoolType.NULL:
			return player.null_pool
		Item.PoolType.LIGHT:
			return player.light_pool
		_:
			return null

func _remove_item_from_world(player: Player3D) -> void:
	"""Remove item billboard from world after pickup

	Args:
		player: Player reference (to access grid/item_renderer)
	"""
	if not player or not player.grid or not player.grid.item_renderer:
		return

	player.grid.item_renderer.remove_item_at(world_position)

	# Also mark as picked up in chunk data
	if ChunkManager and ChunkManager.has_method("get_chunk_at_world_position"):
		var chunk = ChunkManager.get_chunk_at_world_position(world_position)
		if chunk:
			_mark_item_picked_up_in_chunk(chunk, world_position)

func _mark_item_picked_up_in_chunk(chunk: Chunk, world_pos: Vector2i) -> void:
	"""Mark item as picked up in SubChunk data (for persistence)

	Args:
		chunk: Chunk containing the item
		world_pos: World position of the item
	"""
	for subchunk in chunk.sub_chunks:
		for item_data_ref in subchunk.world_items:
			var pos_data = item_data_ref.get("world_position", {})
			var item_world_pos = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))

			if item_world_pos == world_pos:
				item_data_ref["picked_up"] = true
				Log.grid("Marked item at %s as picked up in chunk data" % world_pos)
				return

func get_description() -> String:
	"""Human-readable description for UI

	Returns:
		Action description string
	"""
	return "Pick up %s to slot %d" % [item.item_name if item else "Unknown", slot_index + 1]
