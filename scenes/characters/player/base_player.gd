extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25

@export_group("Movement")
@export var move_speed: float = 8.0
@export var acceleration: float = 20.0
@export var rotation_speed: float = 12.0
@export var jump_impulse: float = 12.0

var _camera_input_direction : Vector2 = Vector2.ZERO
var _last_movement_direction : Vector3 = Vector3.BACK
var _gravity: float = -30

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Node3D = %Camera3D
@onready var _skin: Node3D = %BaseSkin

func  _input(event: InputEvent) -> void:
    if event.is_action_pressed("left_click"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    var is_camera_motion: bool = (
        event is InputEventMouseMotion and 
        Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
    )

    if is_camera_motion:
        _camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
    _camera_pivot.rotation.x += _camera_input_direction.y * delta
    _camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
    _camera_pivot.rotation.y -= _camera_input_direction.x * delta
    _camera_input_direction = Vector2.ZERO

    var raw_input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var forward: Vector3 = _camera.global_basis.z
    var right: Vector3 = _camera.global_basis.x

    var move_direction: Vector3 = forward * raw_input.y + right * raw_input.x
    move_direction.y = 0.0
    move_direction = move_direction.normalized()

    var y_velocity: float = velocity.y
    velocity.y = 0.0
    velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
    velocity.y = y_velocity + _gravity * delta

    var is_starting_jump: bool = Input.is_action_just_pressed("jump") and is_on_floor()


    move_and_slide() 

    if move_direction.length() > 0.2:
        _last_movement_direction = move_direction
    var target_angle: float = Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
    _skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

    if is_starting_jump:
        velocity.y += jump_impulse
        _skin.jump()
    elif not is_on_floor() and velocity.y < 0:
        _skin.fall()
    elif is_on_floor():
        var ground_speed: float = velocity.length()
        if ground_speed > 0.0:
            _skin.move()
        else:
            _skin.idle()