extends Node3D

var rotation_quat := Quaternion.IDENTITY

var rot_speed := 0.003

var pitch_limit := deg_to_rad(89)

var pitch := 0.0
var yaw := 0.0

var zoom_scale := 1.0
var zoom_speed := 0.02

@onready var preload_fits_select = $CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MenuButton

var detector = preload("res://Scenes/detector.tscn")

var selected_detectors := []

func _ready():
	
	for fit_preset in Globals.presets:
		preload_fits_select.add_item(fit_preset)
	
	for observatory_idx in range(len(Globals.lat_obs)):
		var observatory: Node3D = detector.instantiate()
		observatory.obs_name = Globals.name_obs[observatory_idx]
	
		if observatory.obs_name in Globals.hated_ones:
			continue
	
		var theta = Globals.lat_obs[observatory_idx]
		var phi = -Globals.long_obs[observatory_idx]
		
		observatory.lat = theta
		observatory.long = phi
		
		var r = 0.515
		var x =  r * cos(theta) * sin(phi)
		var y =  r * sin(theta)
		var z = -r * cos(theta) * cos(phi)
		observatory.position = Vector3(x, y, z)
		
		add_child(observatory)
		observatory.get_node("Label3D").text = observatory.obs_name
		observatory.look_at(observatory.position * 2)
		
		if observatory.obs_name in Globals.init_on:
			toggle_detector(observatory)
	

func _physics_process(delta):
	$Satellites.rotate_y(delta * 0.03)

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * rot_speed
		pitch -= event.relative.y * rot_speed
		
		pitch = clamp(pitch, -pitch_limit, pitch_limit)
		
		var yaw_quat = Quaternion(Vector3.UP, yaw)
		var pitch_quat = Quaternion(Vector3.RIGHT, pitch)
		
		rotation_quat = yaw_quat * pitch_quat
		
		$Gimbal.transform.basis = Basis(rotation_quat)
	
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
		$Gimbal/Camera3D.position.z -= zoom_speed
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
		$Gimbal/Camera3D.position.z += zoom_speed
	$Gimbal/Camera3D.position.z = clamp($Gimbal/Camera3D.position.z, 0.67, 2)
	
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = event.position
		var from = $Gimbal/Camera3D.project_ray_origin(mouse_pos)
		var to = from + $Gimbal/Camera3D.project_ray_normal(mouse_pos) * 1000  # 1000 units ahead
		var space_state = get_world_3d().direct_space_state
		var param = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(param)
		
		if result:
			if result['collider'].is_in_group("detector"):
				var collider = result['collider']
				toggle_detector(collider)

func toggle_detector(d):
	if d in selected_detectors:
		selected_detectors.erase(d)
	else:
		selected_detectors.append(d)
		if selected_detectors.size() > 5:
			selected_detectors[0].toggle()
			selected_detectors.remove_at(0)
	d.toggle()
	var detectors_s = []
	for det in selected_detectors:
		detectors_s.append(det.obs_name)
	Globals.detectors_on = detectors_s

func _on_fits_button_item_selected(index):
	var fit_file = "res://Assets/saved_maps/" + Globals.presets[index] + "_uv_map.png"
	var tex = ResourceLoader.load(fit_file, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	$Earth/MeshInstance.mesh.material.set_shader_parameter("prob_map", tex)
	$Earth/Probability.mesh.material.set_shader_parameter("prob_map", tex)

func _on_random_event_button_pressed():
	pass # Replace with function body.
