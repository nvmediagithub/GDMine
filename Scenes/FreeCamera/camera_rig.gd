extends Node3D

@export var speed: float = 10.0
@export var mouse_sensitivity: float = 0.1

var yaw: float = 0.0  # горизонтальное вращение в градусах
var pitch: float = 0.0  # вертикальное вращение в градусах

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		# Ограничиваем вертикальный угол от -90 до +90 градусов
		pitch = clamp(pitch, -90, 90)
		# Применяем горизонтальное вращение к этому узлу (CameraRig)
		rotation_degrees.y = yaw
		# Передаём вертикальное вращение дочернему узлу Pivot
		$Pivot.rotation_degrees.x = pitch
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	var input_vector = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_vector.z += 1
	if Input.is_action_pressed("move_backward"):
		input_vector.z -= 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y += 1
	if Input.is_action_pressed("move_down"):
		input_vector.y -= 1
	input_vector = input_vector.normalized()
	
	if input_vector != Vector3.ZERO:
		# Вычисляем базис, основанный только на горизонтальном повороте (yaw)
		var yaw_basis = Basis(Vector3.UP, deg_to_rad(yaw))
		var forward = -yaw_basis.z  # направление "вперёд" по горизонтали
		var right = yaw_basis.x       # направление "вправо" по горизонтали
		
		# Горизонтальное движение рассчитываем как комбинацию forward и right
		var movement = (forward * input_vector.z + right * input_vector.x) 
		# Добавляем вертикальную составляющую (если нужна свободная высота)
		movement += Vector3.UP * input_vector.y
		
		# Перемещаем узел с использованием global_translate
		global_translate(movement * speed * delta)
