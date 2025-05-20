# scenes\characters\player\player.gd
extends CharacterBody3D


@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity: float = 0.002
var rotation_x: float = 0.0

@onready var camera: Camera3D = $"Head/Camera3D"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sensitivity, deg_to_rad(-90), deg_to_rad(90))
		$Head.rotation.x = rotation_x

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
		var ray_direction: Vector3 = camera.project_ray_normal(mouse_pos)
		var ray_end: Vector3 = ray_origin + ray_direction * 10  # Длина луча

		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var result: Dictionary = space_state.intersect_ray(query)

		if result:
			var hit_position: Vector3 = result.position
			print("Точка пересечения:", hit_position)

			# Визуализация точки пересечения
			var sphere_mesh: SphereMesh = SphereMesh.new()
			sphere_mesh.radius = 0.2
			sphere_mesh.height = 0.4
			var sphere_instance: MeshInstance3D = MeshInstance3D.new()
			sphere_instance.name = "HitPoint"
			sphere_instance.mesh = sphere_mesh
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = Color.RED
			sphere_instance.material_override = material
			get_tree().get_root().add_child(sphere_instance)
			sphere_instance.global_transform.origin = hit_position
			var terrain_editor: TerrainEditor = ServiceLocator.resolve("TerrainEditor")
			terrain_editor.remove_voxel(hit_position)
		else:
			print("Нет пересечения с объектами.")
