# camera_controller.gd
extends Camera3D

var mouse_sensitivity: float = 0.002
var mouse_captured: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		# Вращение по горизонтали (вокруг Y)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Вращение по вертикали (вокруг X)
		var vertical_rotation = -event.relative.y * mouse_sensitivity
		rotate_object_local(Vector3.RIGHT, vertical_rotation)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
