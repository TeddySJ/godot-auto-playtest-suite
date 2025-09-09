extends Control
class_name AutoPlaySuiteUiLogViewer

var dict_view : DictTreeViewer

func _ready() -> void:
	minimum_size_changed.connect(custom_minimum_size_changed)
	
	dict_view = DictTreeViewer.new()
	add_child(dict_view)
	
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	var save_button := Button.new()
	save_button.text = "Save Logs"
	save_button.position = Vector2 (100, 350) * ed_scale
	save_button.pressed.connect(_save_button_pressed)
	add_child(save_button)

func _save_button_pressed():
	save_logs_as_json("user://full_log_dump.json")

func save_logs_as_json(path: String):
	if dict_view == null || dict_view.data.size() == 0:
		return
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(dict_view.data, "\t"))  # pretty-print if you like
	file.close()

func set_data(dict : Dictionary):
	dict_view.data = dict

func custom_minimum_size_changed():
	dict_view.custom_minimum_size = custom_minimum_size
