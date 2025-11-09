class_name LoggerPresets
## Logger configuration presets for common debugging scenarios
##
## Usage:
##   LoggerPresets.apply_development()
##   LoggerPresets.apply_input_debug()

## Development: Normal verbosity, key systems only
static func apply_development() -> void:
	Log.set_global_level(Log.Level.DEBUG)
	Log.enable_category(Log.Category.INPUT, false)  # Disabled - only enable for input bugs
	Log.enable_category(Log.Category.STATE, true)
	Log.enable_category(Log.Category.MOVEMENT, true)
	Log.enable_category(Log.Category.ACTION, true)
	Log.enable_category(Log.Category.TURN, true)
	Log.enable_category(Log.Category.GRID, false)
	Log.enable_category(Log.Category.CAMERA, false)
	Log.enable_category(Log.Category.ENTITY, true)
	Log.enable_category(Log.Category.ABILITY, true)
	Log.enable_category(Log.Category.PHYSICS, false)
	Log.enable_category(Log.Category.SYSTEM, true)

## Deep Debug: Everything enabled, trace level
static func apply_deep_debug() -> void:
	Log.set_global_level(Log.Level.TRACE)
	Log.enable_all_categories()
	Log.show_timestamps = true
	Log.show_frame_count = true

## Release: Errors and warnings only
static func apply_release() -> void:
	Log.set_global_level(Log.Level.WARN)
	Log.disable_all_categories()
	Log.enable_category(Log.Category.SYSTEM, true)

## Silent: No logging (for performance testing)
static func apply_silent() -> void:
	Log.set_global_level(Log.Level.NONE)

## Input Debug: Focus on input system only
static func apply_input_debug() -> void:
	Log.set_global_level(Log.Level.TRACE)
	Log.disable_all_categories()
	Log.enable_category(Log.Category.INPUT, true)
	Log.enable_category(Log.Category.SYSTEM, true)

## State Debug: Focus on state machine only
static func apply_state_debug() -> void:
	Log.set_global_level(Log.Level.TRACE)
	Log.disable_all_categories()
	Log.enable_category(Log.Category.STATE, true)
	Log.enable_category(Log.Category.ACTION, true)
	Log.enable_category(Log.Category.TURN, true)
	Log.enable_category(Log.Category.SYSTEM, true)
