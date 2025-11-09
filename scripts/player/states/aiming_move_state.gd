extends PlayerInputState
## Aiming Move State - Player is aiming movement direction
##
## In this state:
## - Left stick/WASD shows movement preview indicator
## - Right trigger/Space confirms movement and executes turn
## - Releasing stick returns to IdleState
## - Holding RT repeats movement with ramping speed

## Track previous direction to detect stick release
var last_direction: Vector2i = Vector2i.ZERO

## RT hold-to-repeat system
var rt_held: bool = false
var rt_hold_time: float = 0.0
var rt_repeat_timer: float = 0.0

# Repeat timing configuration
const INITIAL_DELAY: float = 0.3      # Time before first repeat
const REPEAT_INTERVAL_START: float = 0.25  # Initial repeat rate
const REPEAT_INTERVAL_MIN: float = 0.08    # Fastest repeat rate (ramp target)
const RAMP_TIME: float = 2.0          # Time to reach max speed

func _init() -> void:
	state_name = "AimingMoveState"

func enter() -> void:
	super.enter()
	print("[AimingMoveState] ENTER - Script is loading!")
	if InputManager:
		last_direction = InputManager.get_aim_direction_grid()
	if player:
		player.movement_target = last_direction
		player.update_move_indicator()

	# Check if RT is already being held (from previous state)
	# This allows hold-to-repeat to work across turn executions
	var rt_currently_held = InputManager.is_action_pressed("move_confirm")
	if rt_currently_held and rt_held:
		# RT was held and still is - continue the hold timer
		print("[AimingMoveState] RT still held - continuing hold_time=%.2fs (trigger_value=%.2f)" % [rt_hold_time, InputManager.right_trigger_value])
		pass
	else:
		# Fresh entry or RT not held - reset everything
		print("[AimingMoveState] Fresh enter or RT released (rt_currently_held=%s, rt_held=%s, trigger_value=%.2f)" % [rt_currently_held, rt_held, InputManager.right_trigger_value])
		rt_held = false
		rt_hold_time = 0.0
		rt_repeat_timer = 0.0

func exit() -> void:
	super.exit()
	if player:
		player.hide_move_indicator()

	# Don't reset repeat state here - we want it to persist
	# if RT is still held across turn executions
	# It will be reset in enter() if RT is released

func handle_input(event: InputEvent) -> void:
	# Confirm movement with move_confirm action
	if event.is_action_pressed("move_confirm"):
		_confirm_movement()

func process_frame(delta: float) -> void:
	# Update aim direction from InputManager
	if not InputManager:
		return

	# Check for initial move confirmation (first press)
	if InputManager.is_action_just_pressed("move_confirm"):
		print("[AimingMoveState] RT just pressed - initial move")
		_confirm_movement()
		rt_held = true
		rt_hold_time = 0.0
		rt_repeat_timer = 0.0
		return

	# Track RT hold state for repeat
	var rt_is_down = InputManager.is_action_pressed("move_confirm")

	if rt_is_down and rt_held:
		# RT is being held - update repeat system
		rt_hold_time += delta
		rt_repeat_timer += delta

		# Calculate current repeat interval (ramps from REPEAT_INTERVAL_START to REPEAT_INTERVAL_MIN)
		var ramp_progress = clampf(rt_hold_time / RAMP_TIME, 0.0, 1.0)
		var current_interval = lerp(REPEAT_INTERVAL_START, REPEAT_INTERVAL_MIN, ramp_progress)

		# Check if we should trigger a repeat
		var should_repeat = false
		if rt_hold_time < INITIAL_DELAY:
			# Still in initial delay, no repeats yet
			should_repeat = false
		elif rt_repeat_timer >= current_interval:
			# Repeat interval elapsed
			should_repeat = true
			rt_repeat_timer = 0.0  # Reset for next repeat

		if should_repeat:
			print("[AimingMoveState] REPEAT! hold_time=%.2fs interval=%.2fs" % [rt_hold_time, current_interval])
			_confirm_movement()
			return
	elif not rt_is_down:
		# RT released (don't spam this)
		rt_held = false
		rt_hold_time = 0.0
		rt_repeat_timer = 0.0

	var aim = InputManager.get_aim_direction_grid()

	# Check if stick was released (returned to zero)
	if aim == Vector2i.ZERO and last_direction != Vector2i.ZERO:
		# Player released stick, return to idle
		transition_to("IdleState")
		return

	# Update movement target and indicator
	if aim != last_direction:
		last_direction = aim
		print("[AimingMoveState] Direction changed to: %s" % aim)
		if player:
			player.movement_target = aim
			player.update_move_indicator()

func _confirm_movement() -> void:
	"""Player confirmed movement - execute action and advance turn"""
	if player.movement_target == Vector2i.ZERO:
		print("[AimingMoveState] No movement target, ignoring confirm")
		return

	print("[AimingMoveState] Confirming movement: input_target=%s" % player.movement_target)

	# Get camera-relative direction (for 3D player)
	var actual_direction = player.movement_target
	if player.has_method("get_camera_relative_direction"):
		actual_direction = player.get_camera_relative_direction(player.movement_target)
		print("[AimingMoveState] After camera transform: actual_direction=%s" % actual_direction)

	# Create movement action with camera-relative direction
	var action = MovementAction.new(actual_direction)
	print("[AimingMoveState] Created MovementAction with direction=%s" % actual_direction)

	# Validate and execute
	if action.can_execute(player):
		# Transition to executing state
		player.pending_action = action
		transition_to("ExecutingTurnState")
	else:
		print("[AimingMoveState] Invalid movement - blocked!")
		# Could add visual/audio feedback here
