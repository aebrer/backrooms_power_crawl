extends Node3D
## Main game scene - 3D version

@onready var grid: Grid3D = $Grid3D
@onready var player: Player3D = $Player3D
@onready var move_indicator: Node3D = $MoveIndicator
@onready var ui_turn_counter: Label = $UI/TurnCounter
@onready var ui_instructions: Label = $UI/Instructions

func _ready() -> void:
	print("[Game3D] Initializing 3D turn-based roguelike...")

	# Initialize grid
	grid.initialize(Grid3D.GRID_SIZE)

	# Link player to grid and indicator
	player.grid = grid
	player.move_indicator = move_indicator

	print("[Game3D] Ready! Controls: Left stick/WASD to aim, RT/Space to move")

func _process(_delta: float) -> void:
	# Update UI (same as 2D version)
	if player and player.state_machine:
		ui_turn_counter.text = "Turn: %d | Pos: %s | State: %s" % [
			player.turn_count,
			player.grid_position,
			player.state_machine.get_current_state_name()
		]
