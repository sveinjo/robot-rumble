extends MeshInstance3D

# Script to ensure viewport texture is properly connected to the 3D screen

func _ready():
	# Get the viewport
	var viewport = get_node("../SubViewport")
	if viewport:
		print("Viewport found, size: ", viewport.size, " update mode: ", viewport.render_target_update_mode)
		
		# Force viewport to render
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		# Get the material (Godot 4 API)
		var mat = get_surface_override_material(0)
		if mat:
			# Set the viewport texture directly
			mat.albedo_texture = viewport.get_texture()
			print("Viewport texture connected to 3D screen")
			print("Texture size: ", viewport.get_texture().get_size() if viewport.get_texture() else "null")
		else:
			print("ERROR: No surface override material found on Screen3D")
			# Try to create and set a new material
			var new_mat = StandardMaterial3D.new()
			new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			new_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			new_mat.albedo_texture = viewport.get_texture()
			new_mat.emission_enabled = true
			new_mat.emission = Color.WHITE
			new_mat.emission_energy_multiplier = 1.0
			set_surface_override_material(0, new_mat)
			print("Created new material with viewport texture")
			print("New texture size: ", viewport.get_texture().get_size() if viewport.get_texture() else "null")
	else:
		print("ERROR: SubViewport not found")
