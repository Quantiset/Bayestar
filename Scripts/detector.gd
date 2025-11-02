extends Node3D

var obs_name := ""
var lat := 0.0
var long := 0.0

var is_selected := false

@onready var mat: StandardMaterial3D = $MeshInstance3D.get_surface_override_material(0)
var col: Color;

func _ready():
	col = mat.albedo_color

func toggle():
	if is_selected:
		mat.albedo_color = col;
		is_selected = false
	else:
		mat.albedo_color = Color("ffffff");
		is_selected = true
