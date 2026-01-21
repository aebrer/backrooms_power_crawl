extends SceneTree
## Run with: godot --headless --script _claude_scripts/generate_wall_mesh.gd
##
## Generates a wall box mesh with different materials per face and saves it.
## The mesh has 6 surfaces:
## - Surface 0: Bottom face (floor material) - visible from ABOVE (normal UP)
## - Surface 1: Top face (ceiling material) - visible from BELOW (normal DOWN)
## - Surfaces 2-5: Side faces (wall material) - visible from OUTSIDE

func _init():
	print("=" .repeat(60))
	print("Generating multi-material wall mesh...")
	print("=" .repeat(60))

	# Load materials
	var floor_mat = load("res://assets/levels/level_00/floor_brown.tres")
	var wall_mat = load("res://assets/levels/level_00/wall_yellow.tres")
	var ceiling_mat = load("res://assets/levels/level_00/ceiling_acoustic.tres")

	if not floor_mat or not wall_mat or not ceiling_mat:
		push_error("Failed to load materials!")
		quit(1)
		return

	# Box dimensions: 2x4x2, centered at y=2 (bottom at y=0, top at y=4)
	var half_x := 1.0
	var half_z := 1.0
	var y_bottom := 0.0
	var y_top := 4.0

	var mesh := ArrayMesh.new()

	# Surface 0: Bottom face (floor) at y=0
	# Visible from above, so normal points UP
	# CCW winding when viewed from above (looking down at floor)
	_add_quad(mesh, floor_mat,
		Vector3(-half_x, y_bottom, -half_z),  # back-left
		Vector3(half_x, y_bottom, -half_z),   # back-right
		Vector3(half_x, y_bottom, half_z),    # front-right
		Vector3(-half_x, y_bottom, half_z),   # front-left
		Vector3.UP)

	# Surface 1: Top face (ceiling) at y=4
	# Visible from below, so normal points DOWN
	# CCW winding when viewed from below
	_add_quad(mesh, ceiling_mat,
		Vector3(-half_x, y_top, -half_z),   # back-left
		Vector3(half_x, y_top, -half_z),    # back-right
		Vector3(half_x, y_top, half_z),     # front-right
		Vector3(-half_x, y_top, half_z),    # front-left
		Vector3.DOWN)

	# Surface 2: Front face (+Z) - visible from +Z direction
	# CCW winding when viewed from +Z
	_add_quad(mesh, wall_mat,
		Vector3(-half_x, y_bottom, half_z),  # bottom-left
		Vector3(-half_x, y_top, half_z),     # top-left
		Vector3(half_x, y_top, half_z),      # top-right
		Vector3(half_x, y_bottom, half_z),   # bottom-right
		Vector3(0, 0, 1))  # +Z normal

	# Surface 3: Back face (-Z) - visible from -Z direction
	# CCW winding when viewed from -Z
	_add_quad(mesh, wall_mat,
		Vector3(half_x, y_bottom, -half_z),  # bottom-left (from -Z view)
		Vector3(half_x, y_top, -half_z),     # top-left
		Vector3(-half_x, y_top, -half_z),    # top-right
		Vector3(-half_x, y_bottom, -half_z), # bottom-right
		Vector3(0, 0, -1))  # -Z normal

	# Surface 4: Right face (+X) - visible from +X direction
	# CCW winding when viewed from +X
	_add_quad(mesh, wall_mat,
		Vector3(half_x, y_bottom, half_z),   # bottom-left (from +X view)
		Vector3(half_x, y_top, half_z),      # top-left
		Vector3(half_x, y_top, -half_z),     # top-right
		Vector3(half_x, y_bottom, -half_z),  # bottom-right
		Vector3(1, 0, 0))  # +X normal

	# Surface 5: Left face (-X) - visible from -X direction
	# CCW winding when viewed from -X
	_add_quad(mesh, wall_mat,
		Vector3(-half_x, y_bottom, -half_z), # bottom-left (from -X view)
		Vector3(-half_x, y_top, -half_z),    # top-left
		Vector3(-half_x, y_top, half_z),     # top-right
		Vector3(-half_x, y_bottom, half_z),  # bottom-right
		Vector3(-1, 0, 0))  # -X normal

	# Save the mesh
	var save_path := "res://assets/levels/level_00/wall_multimat.tres"
	var err := ResourceSaver.save(mesh, save_path)
	if err == OK:
		print("SUCCESS: Saved mesh to: ", save_path)
	else:
		push_error("Failed to save mesh: error ", err)
		quit(1)
		return

	quit(0)


func _add_quad(mesh: ArrayMesh, material: Material, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> void:
	# Vertices in CCW order when viewed from the normal direction
	var vertices := PackedVector3Array([v0, v1, v2, v3])
	var normals := PackedVector3Array([normal, normal, normal, normal])

	# UVs: v0=bottom-left, v1=top-left, v2=top-right, v3=bottom-right
	var uvs := PackedVector2Array([
		Vector2(0, 1),  # v0: bottom-left
		Vector2(0, 0),  # v1: top-left
		Vector2(1, 0),  # v2: top-right
		Vector2(1, 1),  # v3: bottom-right
	])

	# Two triangles: 0-1-2 and 0-2-3 (CCW)
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)
