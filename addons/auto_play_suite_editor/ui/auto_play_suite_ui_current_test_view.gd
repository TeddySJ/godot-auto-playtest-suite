extends AutoPlaySuiteUiView
class_name AutoPlaySuiteUiCurrentTestView

var action_list : AutoPlaySuiteActionList
var file_dialog : FileDialog

var premature_end_is_error : CheckButton

var save_test_button : Button
var save_test_as_button : Button

var currently_setting_new_test : bool = false
var current_file_path : String = ""

var current_test : AutoPlaySuiteTestResource
var test_name_field : LineEdit

signal signal_on_about_to_change_from_action(current_action)
signal signal_on_test_name_changed(new_name)
signal signal_on_action_list_item_selected(action_resource)
signal signal_on_current_test_saved(uid_string)

func _ready() -> void:
	
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()

	
	action_list = AutoPlaySuiteActionList.new()
	add_child(action_list)
	action_list.signal_on_list_changed.connect(_sync_current_test_to_list)
	
	action_list.custom_minimum_size.x = 250 * ed_scale
	action_list.custom_minimum_size.y = 300 * ed_scale
	
	action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	
	premature_end_is_error = CheckButton.new()
	premature_end_is_error.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(0, 50)  * ed_scale
	premature_end_is_error.text = "Unexpected End is Error"
	add_child(premature_end_is_error)
	premature_end_is_error.toggled.connect(_toggled_premature_end_is_error)
	
	save_test_button = Button.new()
	save_test_button.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(0, 100)  * ed_scale
	save_test_button.text = "Save Test"
	add_child(save_test_button)
	save_test_button.pressed.connect(_save_test)
	
	save_test_as_button = Button.new()
	save_test_as_button.position = save_test_button.position + Vector2(100, 0) * ed_scale
	save_test_as_button.text = "Save Test As"
	add_child(save_test_as_button)
	save_test_as_button.pressed.connect(_save_test_as)
	
	test_name_field = LineEdit.new()
	test_name_field.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(100, 10)  * ed_scale
	test_name_field.custom_minimum_size.x = 200 * ed_scale
	test_name_field.text_changed.connect(_test_name_field_changed)
	add_child(test_name_field)
	
	var test_name_label = Label.new()
	test_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	test_name_label.text = "Test Name:"
	test_name_label.position = test_name_field.position + Vector2(-210, 5)  * ed_scale
	test_name_label.custom_minimum_size.x = 200 * ed_scale
	add_child(test_name_label)


func _on_action_list_item_selected():
	var selected = action_list.currently_selected
	var action_resource : AutoPlaySuiteActionResource = action_list.backing_dictionary[selected]
	signal_on_action_list_item_selected.emit(action_resource)

func _on_selected_action_id_changed(new_id : String):
	action_list.update_display_text_of_selected_index()

func _save_test(path : String = ""):
	if file_dialog != null:
		return
	if action_list.get_item_count() == 0:
		return
	
	if path == "":
		if current_file_path == "":
			_save_test_as()
			return
		path = current_file_path
	
	if path.begins_with("u"):
		path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	
	current_file_path = path
	
	_sync_current_test_to_list()
	
	var create : bool = current_test.test_uid == ""
	
	current_test.take_over_path(path)
	ResourceSaver.save(current_test, path)
	
	var uid : int = ResourceSaver.get_resource_id_for_path(path)
	var uid_string : String = ResourceUID.id_to_text(uid)
	current_test.test_uid = uid_string
	
	if create:
		ResourceSaver.save(current_test, path) # Save again to store UID
	
	signal_on_current_test_saved.emit(uid_string)

func _save_test_as():
	if action_list.get_item_count() == 0:
		return

	if file_dialog != null:
		return
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	_set_file_dialog_size_and_position()
	file_dialog.show()
	file_dialog.add_filter("*.test.tres")
	file_dialog.canceled.connect(_file_dialog_canceled)
	file_dialog.file_selected.connect(_save_file_chosen)

func _save_file_chosen(path : String):
	file_dialog = null
	_save_test(path)

func _sync_current_test_to_list():
	if currently_setting_new_test:
		return
	
	current_test.actions.clear()
	var all_actions : Array = action_list.get_all_items()
	current_test.actions.append_array(all_actions)

func new_test():
	current_file_path = ""
	current_test = AutoPlaySuiteTestResource.new()
	var test_name : String = "test #"
	for n in 4:
		test_name += str(randi_range(0,9)) 
	test_name_field.text = test_name
	current_test.test_name = test_name
	action_list.empty_list()
	action_list.add_default_entry(0)
	
func set_current_test(new_test : AutoPlaySuiteTestResource):
	currently_setting_new_test = true
	current_test = new_test
	test_name_field.text = current_test.test_name
	premature_end_is_error.button_pressed = current_test.premature_end_is_error
	action_list.empty_list()
	for action in current_test.actions:
		action_list.add_and_bind_item(action.action_id, action)	
	currently_setting_new_test = false

func _file_dialog_canceled():
	file_dialog = null

func _test_name_field_changed(new_name : String):
	current_test.test_name = new_name
	signal_on_test_name_changed.emit(new_name)

func _set_file_dialog_size_and_position():
	file_dialog.min_size = Vector2(600, 400) * AutoPlaySuite._get_plugin_singleton().editor_scale
	file_dialog.position = global_position

func handle_input(event: InputEvent) -> void:
	action_list.handle_input(event)

func _toggled_premature_end_is_error(on : bool):
	current_test.premature_end_is_error = on
