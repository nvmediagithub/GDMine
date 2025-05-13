extends Control

const TARGET_SCENE_PATH: String = "res://scenes/test/test_chunk_manager_level.tscn"

@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

var loading_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.THREAD_LOAD_IN_PROGRESS
var progress: Array = [0.0]

func _ready() -> void:
	ResourceLoader.load_threaded_request(TARGET_SCENE_PATH)

func _process(_delta: float) -> void:
	loading_status = ResourceLoader.load_threaded_get_status(TARGET_SCENE_PATH, progress)
	print(progress)
	match loading_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene: PackedScene = ResourceLoader.load_threaded_get(TARGET_SCENE_PATH)
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Не удалось загрузить сцену: %s" % TARGET_SCENE_PATH)
