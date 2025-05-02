extends Camera3D
class_name FreeCamera

@export var move_speed: float = 10.0
@export var mouse_sensitivity: float = 0.005

var rotation_enabled: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and rotation_enabled:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_x(-event.relative.y * mouse_sensitivity)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		rotation_enabled = event.pressed
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if rotation_enabled else Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	var dir: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	if Input.is_action_pressed("move_up"):
		dir += transform.basis.y
	if Input.is_action_pressed("move_down"):
		dir -= transform.basis.y

	if dir != Vector3.ZERO:
		translate(dir.normalized() * move_speed * delta)
