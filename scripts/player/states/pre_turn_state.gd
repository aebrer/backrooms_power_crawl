extends PlayerInputState
## Pre-Turn State - Regenerate resources before action execution
##
## In this state:
## - Input is blocked (player cannot interrupt)
## - Resource regeneration happens:
##   - HP: hp_regen_percent % of max HP (from perks)
##   - Sanity: sanity_regen_percent % of max Sanity (from perks)
##   - Mana: NULL/2 base + mana_regen_percent % of max Mana (from perks)
## - Transitions to ExecutingTurnState to execute the pending action

func _init() -> void:
	state_name = "PreTurnState"

func enter() -> void:
	super.enter()
	# Block input during pre-turn processing
	if player:
		player.hide_move_indicator()
	# Execute pre-turn processing immediately
	_execute_pre_turn()

func handle_input(_event: InputEvent) -> void:
	# Block all input during pre-turn processing
	pass

func _execute_pre_turn() -> void:
	"""Execute pre-turn processing (resource regeneration, future: status effects, etc.)"""
	if not player:
		Log.error(Log.Category.TURN, "No player in PreTurnState!")
		transition_to("IdleState")
		return

	Log.turn("===== TURN %d PRE-TURN =====" % (player.turn_count + 1))

	# Regenerate all resources (HP, Sanity, Mana)
	if player.stats:
		player.stats.regenerate_resources()

	# TODO: Process start-of-turn status effects (buffs, debuffs, etc.)
	# TODO: Process environmental effects that trigger at turn start

	# Transition to ExecutingTurnState to execute the pending action
	transition_to("ExecutingTurnState")
