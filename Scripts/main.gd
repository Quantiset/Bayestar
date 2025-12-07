extends Node3D

var rotation_quat := Quaternion.IDENTITY

var rot_speed := 0.003

var pitch_limit := deg_to_rad(89)

var pitch := 0.0
var yaw := 0.0

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

var detector = preload("res://Scenes/detector.tscn")

var selected_detectors := []

func _ready():
	
	$DirectionalLight3D.position = 100*Vector3(
		sin($DirectionalLight3D.rotation.y) * cos($DirectionalLight3D.rotation.x),
		-sin($DirectionalLight3D.rotation.x),
		cos($DirectionalLight3D.rotation.y) * cos($DirectionalLight3D.rotation.x)
	)
	
	for fit_preset in Globals.presets:
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
	
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("sun_position", $DirectionalLight3D.global_position)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("planet_position", $Earth.global_position)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("planet_radius", 0.48)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("atmosphere_radius", 1.11)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("z_near", cam.near)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("z_far", cam.far)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("scattering_coeffs", Vector3(
		pow(800.0 / 750, 4),
		pow(800.0 / 570, 4),
		pow(800.0 / 475, 4)
	) * 1.0)

func _physics_process(delta):
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("camera_position", cam.global_position)
	$Gimbal/Camera3D/Atmosphere.mesh.material.set_shader_parameter("camera_basis", cam.global_transform.basis)
	
	$DirectionalLight3D.rotate_y(delta * 0.03)
	var light_direction = -$DirectionalLight3D.global_transform.basis.z
	$DirectionalLight3D.position = 100*Vector3(
		sin($DirectionalLight3D.rotation.y) * cos($DirectionalLight3D.rotation.x),
		-sin($DirectionalLight3D.rotation.x),
		cos($DirectionalLight3D.rotation.y) * cos($DirectionalLight3D.rotation.x)
	)
	$Earth/MeshInstance.mesh.material.set_shader_parameter("light_direction", light_direction)
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
		cam.position.z -= zoom_speed
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
		cam.position.z += zoom_speed
	cam.position.z = clamp(cam.position.z, 0.67, 2)
	
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = event.position
		var from = cam.project_ray_origin(mouse_pos)
		var to = from + cam.project_ray_normal(mouse_pos) * 1000  # 1000 units ahead
		var space_state = get_world_3d().direct_space_state
		var param = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(param)
		
		if result:
			if result['collider'].is_in_group("detector"):
				var collider = result['collider']
				toggle_detector(collider)
			else:
				$LineRot.look_at(result.position)

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
	$CanvasLayer/MarginContainer/VBoxContainer/ActivatedList.text = \
		"Activated List:\n" + "\n".join(detectors_s)

func _on_fits_button_item_selected(index):
	var fit_file = "res://Assets/saved_maps/" + Globals.presets[index] + "_uv_map.png"
	update_prob_map(fit_file)

func _on_random_event_button_pressed():
	if not Input.is_action_pressed("ui_shift"):
		Globals.load_prob_file()
	update_prob_map("res://Assets/uv_map.png")

func _on_gradient_button_item_selected(index: int) -> void:
	$Earth/Probability.mesh.material.set_shader_parameter("gradient", gradients[gradients.keys()[index]])

func update_prob_map(fit_file):
	for i in range(10):
		await get_tree().process_frame
	var tex = ResourceLoader.load(fit_file, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	for i in range(10):
		await get_tree().process_frame
	$Earth/MeshInstance.mesh.material.set_shader_parameter("prob_map", tex)
	$Earth/Probability.mesh.material.set_shader_parameter("prob_map", tex)
