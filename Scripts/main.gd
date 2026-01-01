extends Node3D

var rotation_quat := Quaternion.IDENTITY
var rot_speed := 0.003
var pitch_limit := deg_to_rad(89)
var pitch := 0.0
var yaw := 0.0
var pitch_stand := 0.0
var yaw_stand := 0.0
var linerot_position := Vector3()
var surface_normal := Vector3.UP
var north_reference := Vector3.FORWARD

@onready var cam := $Gimbal/Camera3D
var zoom_scale := 1.0
var zoom_speed := 0.02

var gradients = {
	"Purple Fire": preload("res://Assets/gradients/purplefire.tres"),
	"Electric Blue": preload("res://Assets/gradients/ElectricBlue.tres"),
	"Prism": preload("res://Assets/gradients/Prism.tres")
}

@onready var preload_fits_select = $CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MenuButton
@onready var gradients_select = $CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer2/OptionButton
@onready var rotating_atmosphere = $Gimbal/Camera3D/Atmosphere
@onready var standing_atmosphere = $Earth/StandingGimbal/StandingCamera/Atmosphere

var detector = preload("res://Scenes/detector.tscn")
var selected_detectors := []
@onready var current_atmosphere = rotating_atmosphere
var is_in_global_mode := true

func _ready():
	
	if OS.get_name() == "Web":
		$CanvasLayer/MarginContainer/VBoxContainer/Random/RandomEventButton.hide()
	
	for fit_preset in Globals.presets.values():
		preload_fits_select.add_item(fit_preset)
	
	for gradient in gradients:
		gradients_select.add_item(gradient)
	
	for observatory_idx in range(len(Globals.lat_obs)):
		var observatory: Node3D = detector.instantiate()
		observatory.obs_name = Globals.name_obs[observatory_idx]
		if observatory.obs_name in Globals.hated_ones:
			continue
		var theta = Globals.lat_obs[observatory_idx]
		var phi = -Globals.long_obs[observatory_idx]
		observatory.lat = theta
		observatory.long = phi
		var r = 0.509
		var x =  r * cos(theta) * sin(phi)
		var y =  r * sin(theta)
		var z = -r * cos(theta) * cos(phi)
		observatory.position = Vector3(x, y, z)
		observatory.scale *= 0.75
		$Earth.add_child(observatory)
		observatory.get_node("Label3D").text = observatory.obs_name
		observatory.look_at(observatory.position * 2)
		observatory.rotate(observatory.position.normalized(), randf())
		if observatory.obs_name in Globals.init_on:
			toggle_detector(observatory)
	
	update_atmosphere(current_atmosphere)

func _physics_process(delta):
	$Earth.rotate_y(delta * 0.03)
	var light_dir = -$DirectionalLight3D.global_transform.basis.z.normalized()
	var planet_pos = $Earth.global_transform.origin
	var sun_pos = planet_pos - light_dir * 100.0
	var mat = current_atmosphere.mesh.material
	mat.set_shader_parameter("sun_position", sun_pos)
	mat.set_shader_parameter("camera_position", cam.global_position)
	mat.set_shader_parameter("camera_basis", cam.global_transform.basis)
	$Earth/MeshInstance.mesh.material.set_shader_parameter("light_direction", light_dir)
	
	surface_normal = $Earth/StandingGimbal.global_position.normalized()
	var helper = Vector3.UP if abs(surface_normal.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
	var east = helper.cross(surface_normal).normalized()
	north_reference = surface_normal.cross(east).normalized()
	update_standing_rotation()

func _input(event):
	var dragging := false
	var delta := Vector2.ZERO

	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			dragging = true
			delta = event.relative * 0.7
	elif event is InputEventScreenDrag:
		dragging = true
		delta = event.relative * 0.7

	if dragging:
		if is_in_global_mode:
			yaw -= delta.x * rot_speed
			pitch -= delta.y * rot_speed
			pitch = clamp(pitch, -pitch_limit, pitch_limit)
			$Gimbal.transform.basis = Basis(Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.RIGHT, pitch))
		else:
			yaw_stand -= delta.x * rot_speed
			pitch_stand -= delta.y * rot_speed
			pitch_stand = clamp(pitch_stand, deg_to_rad(0.1), deg_to_rad(89.5))
			update_standing_rotation()
	
	if is_in_global_mode:
		if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			cam.position.z -= zoom_speed
		if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			cam.position.z += zoom_speed
		cam.position.z = clamp(cam.position.z, 0.67, 2)
	
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = event.position
		var from = cam.project_ray_origin(mouse_pos)
		var to = from + cam.project_ray_normal(mouse_pos) * 1000
		var space_state = get_world_3d().direct_space_state
		var param = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(param)
		if result:
			if result['collider'].is_in_group("detector"):
				toggle_detector(result['collider'])
			else:
				$LineRot.look_at(result.position)
				linerot_position = result.position
	
	if Input.is_action_just_pressed("land_camera"):
		toggle_view()
	
	if Input.is_action_just_pressed("ui_cancel"):
		update_atmosphere(rotating_atmosphere)

func update_standing_rotation():
	var look_dir_h = north_reference.rotated(surface_normal, yaw_stand)
	var local_right = surface_normal.cross(look_dir_h).normalized()
	var final_look_dir = look_dir_h.rotated(local_right, -pitch_stand)
	
	if final_look_dir.is_equal_approx(surface_normal):
		$Earth/StandingGimbal.look_at($Earth/StandingGimbal.global_position + final_look_dir, north_reference)
	else:
		$Earth/StandingGimbal.look_at($Earth/StandingGimbal.global_position + final_look_dir, surface_normal)

func toggle_view():
	var pos := linerot_position
	if is_in_global_mode and pos:
		$Earth/StandingGimbal/StandingCamera.current = true
		$Earth/StandingGimbal.global_position = pos * 1.01
		surface_normal = pos.normalized()
		var helper = Vector3.UP if abs(surface_normal.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		var east = helper.cross(surface_normal).normalized()
		north_reference = surface_normal.cross(east).normalized()
		pitch_stand = deg_to_rad(20)
		yaw_stand = 0.0
		update_standing_rotation()
		update_atmosphere(standing_atmosphere)
		$LineRot.visible = false
		is_in_global_mode = false
	else:
		update_atmosphere(rotating_atmosphere)
		is_in_global_mode = true

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
	$CanvasLayer/MarginContainer/VBoxContainer/ActivatedList.text = "Activated List:\n" + "\n".join(detectors_s)

func _on_fits_button_item_selected(index):
	update_prob_map("res://Assets/saved_maps/" + Globals.presets.keys()[index] + "_uv_map.png")

func _on_random_event_button_pressed():
	if not Input.is_action_pressed("ui_shift"):
		Globals.load_prob_file()
	update_prob_map("res://Assets/uv_map.png")

func _on_gradient_button_item_selected(index: int) -> void:
	$Probability.mesh.material.set_shader_parameter("gradient", gradients[gradients.keys()[index]])

func update_prob_map(fit_file):
	for i in range(5): await get_tree().process_frame
	var tex = ResourceLoader.load(fit_file, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	for i in range(5): await get_tree().process_frame
	$Earth/MeshInstance.mesh.material.set_shader_parameter("prob_map", tex)
	$Probability.mesh.material.set_shader_parameter("prob_map", tex)

func update_atmosphere(atm):
	$LineRot.visible = true
	current_atmosphere = atm
	if current_atmosphere == standing_atmosphere:
		$Earth/Cloud.hide()
		cam = $Earth/StandingGimbal/StandingCamera
	else:
		$Earth/Cloud.show()
		cam = $Gimbal/Camera3D
	cam.make_current()
	var m = current_atmosphere.mesh.material
	m.set_shader_parameter("planet_position", $Earth.global_position)
	m.set_shader_parameter("planet_radius", 0.48)
	m.set_shader_parameter("atmosphere_radius", 1.21)
	m.set_shader_parameter("z_near", cam.near)
	m.set_shader_parameter("z_far", cam.far)
	m.set_shader_parameter("density_falloff", 30.0)
	m.set_shader_parameter("sample_points", 12)
	m.set_shader_parameter("scattering_coeffs", Vector3(pow(600.0/750,4), pow(600.0/570,4), pow(600.0/475,4)) * 2.0)
