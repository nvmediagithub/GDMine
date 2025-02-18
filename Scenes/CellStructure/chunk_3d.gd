# chunk_3d.gd
extends Node3D
class_name Chunk3D

# Ссылка на объект типа ChunkSlice, который содержит линии для отрисовки
var slice: ChunkSlice = null

func _ready() -> void:
	print("New chunk")
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3(1, 1, 1)  # Размер заглушки, подберите по необходимости
	var placeholder: MeshInstance3D = MeshInstance3D.new()
	placeholder.mesh = cube
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	placeholder.set_surface_override_material(0, mat)
	#placeholder.position = Vector3(0, 0, 0)
	add_child(placeholder)
	# Если slice уже установлен, обновляем геометрию
	#if slice:
		#update_geometry()

func set_chunk(new_chunk: ChunkSlice) -> void:
	slice = new_chunk
	update_geometry()

func update_geometry() -> void:
	if slice == null:
		return

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.set_color(Color(0.0, 1.0, 0.0))  # Зеленый цвет линий

	# Проходим по всем линиям, сохраненным в slice
	for line: CellLine in slice.lines:
		# Ожидается, что line.start.position и line.end.position – Vector2 или Vector3.
		# Если они Vector2, мы интерпретируем x как X, а y как Z, устанавливая Y=0.
		var start_pos: Vector3 = Vector3(line.start.position.x, 0, line.start.position.y)
		var end_pos: Vector3 = Vector3(line.end.position.x, 0, line.end.position.y)
		st.add_vertex(start_pos)
		st.add_vertex(end_pos)
	var new_mesh: ArrayMesh = st.commit()
	# Создаем новый узел MeshInstance3D, задаем ему меш и добавляем как дочерний
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = new_mesh
	add_child(mesh_instance)
