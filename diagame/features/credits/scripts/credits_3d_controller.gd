extends Node3D

# Script to project different 2D scenes onto each 3D wall

@onready var viewport = $SubViewport
@onready var screen_front = $Screen3D
@onready var screen_right = $Screen3D_Right
@onready var screen_left = $Screen3D_Left
@onready var screen_back = $Screen3D_Back

func _ready():
	var viewport_right = _duplicate_viewport(viewport, "SubViewport_Right")
	var viewport_left = _duplicate_viewport(viewport, "SubViewport_Left")

	_populate_viewport(viewport, "res://features/credits/scenes/credits.tscn")
	_populate_viewport(viewport_right, "res://features/credits/scenes/charge_megacharge1.tscn")
	_populate_viewport(viewport_left, "res://features/credits/scenes/charge.tscn")

	_assign_wall_texture(screen_front, viewport)
	_assign_wall_texture(screen_right, viewport_right)
	_assign_wall_texture(screen_left, viewport_left)
	_assign_wall_texture(screen_back, viewport)

func _duplicate_viewport(source_viewport: SubViewport, viewport_name: String) -> SubViewport:
	var new_viewport = source_viewport.duplicate()
	new_viewport.name = viewport_name
	add_child(new_viewport)
	return new_viewport

func _populate_viewport(target_viewport: SubViewport, scene_path: String) -> void:
	target_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for child in target_viewport.get_children():
		if child.name != "Background":
			child.queue_free()
	var scene_resource = load(scene_path)
	if scene_resource:
		target_viewport.add_child(scene_resource.instantiate())

func _assign_wall_texture(wall: MeshInstance3D, source_viewport: SubViewport) -> void:
	var material = wall.get_surface_override_material(0)
	if material and source_viewport:
		var wall_material = material.duplicate()
		wall.set_surface_override_material(0, wall_material)
		wall_material.albedo_texture = source_viewport.get_texture()
