extends Node3D

@export var area_size: float = 50.0  # Размер области (для демо можно не использовать явно)
@export var extrusion_height: float = 2.0  # Если нужно экструзировать (опционально)

var cell_structure: CellStructure

func _ready() -> void:
	# Загружаем модуль алгоритма
	cell_structure = preload("res://Scripts/CellStructure/cell_structure.gd").new()
	# Настраиваем параметры по необходимости (уже заданы через экспорт)
	cell_structure.generate_structure()
	_draw_structure()

func _draw_structure() -> void:
	# Создаем ImmediateMesh для отрисовки линий (ребер)
	var im = ImmediateMesh.new()
	add_child(im)
	im.clear()
	im.begin(Mesh.PRIMITIVE_LINES)
	im.set_color(Color.GREEN)
	for edge in cell_structure.edges:
		im.add_vertex(edge["from"])
		im.add_vertex(edge["to"])
	im.end()
	
	# Отрисовываем точки как маленькие сферы
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	for p in cell_structure.points:
		var mi = MeshInstance3D.new()
		mi.mesh = sphere_mesh
		mi.translation = p
		add_child(mi)
