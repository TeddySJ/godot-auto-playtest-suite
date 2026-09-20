extends AutoPlaySuiteUiView
class_name AutoPlaySuiteUiCurrentTestView

enum CurrentList
{
	Main,
	Post,
}

var current_list : CurrentList = CurrentList.Main

var action_list : AutoPlaySuiteActionList
var post_action_list : AutoPlaySuiteActionList
var file_dialog : FileDialog

var premature_end_is_error : CheckButton

var main_actions_button : Button
var post_actions_button : Button

var save_test_button : Button
var save_test_as_button : Button

var currently_setting_new_test : bool = false
var current_file_path : String = ""

var current_test : AutoPlaySuiteTestResource
var test_name_field : LineEdit

var _layout_current_bot_element : int = 0

var editor_scale = 1

signal signal_on_about_to_change_from_action(current_action)
signal signal_on_test_name_changed(new_name)
signal signal_on_action_list_item_selected(action_resource)
signal signal_on_current_test_saved(uid_string)
signal signal_on_action_list_changed
signal signal_on_current_test_modified(test : AutoPlaySuiteTestResource)
signal signal_on_before_test_change
signal signal_on_before_test_save
signal signal_on_before_action_context_change

func _ready() -> void:
	
	if Engine.is_editor_hint():
		editor_scale = EditorInterface.get_editor_scale()

	
	action_list = AutoPlaySuiteActionList.new()
	add_child(action_list)
	action_list.signal_on_list_changed.connect(_sync_current_test_to_list)
	
	action_list.custom_minimum_size.x = 250 * editor_scale
	action_list.custom_minimum_size.y = 300 * editor_scale
	
	action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	
	post_action_list = AutoPlaySuiteActionList.new()
	add_child(post_action_list)
	post_action_list.signal_on_list_changed.connect(_sync_current_test_to_list)
	
	post_action_list.custom_minimum_size.x = 250 * editor_scale
	post_action_list.custom_minimum_size.y = 300 * editor_scale
	
	post_action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	post_action_list.visible = false
	
	main_actions_button = Button.new()
	main_actions_button.position = get_position_of_next_element()
	main_actions_button.text = "Main List"
	main_actions_button.focus_mode = Control.FOCUS_NONE
	add_child(main_actions_button)
	main_actions_button.pressed.connect(_set_list_to_main_actions)
	main_actions_button.disabled = true
	
	post_actions_button = Button.new()
	post_actions_button.position = main_actions_button.position + Vector2(100, 0) * editor_scale
	post_actions_button.text = "Post List"
	post_actions_button.focus_mode = Control.FOCUS_NONE
	add_child(post_actions_button)
	post_actions_button.pressed.connect(_set_list_to_post_actions)
	
	premature_end_is_error = CheckButton.new()
	premature_end_is_error.position = get_position_of_next_element()
	premature_end_is_error.text = "Unexpected End is Error"
	add_child(premature_end_is_error)
	premature_end_is_error.toggled.connect(_toggled_premature_end_is_error)
	
	test_name_field = LineEdit.new()
	test_name_field.position = get_position_of_next_element()
	test_name_field.custom_minimum_size.x = 200 * editor_scale
	test_name_field.text_changed.connect(_test_name_field_changed)
	add_child(test_name_field)
	
	var test_name_label = Label.new()
	test_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	test_name_label.text = "Test Name:"
	test_name_label.position = test_name_field.position + Vector2(-210, 5)  * editor_scale
	test_name_label.custom_minimum_size.x = 200 * editor_scale
	add_child(test_name_label)
	
	save_test_button = Button.new()
	save_test_button.position = get_position_of_next_element()
	save_test_button.text = "Save Test"
	add_child(save_test_button)
	save_test_button.pressed.connect(_save_test)
	
	save_test_as_button = Button.new()
	save_test_as_button.position = save_test_button.position + Vector2(100, 0) * editor_scale
	save_test_as_button.text = "Save Test As"
	add_child(save_test_as_button)
	save_test_as_button.pressed.connect(_save_test_as)
	
func get_position_of_next_element() -> Vector2:
	var lower_elements_start = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(0, 10)  * editor_scale
	var between_elements : float = 40 * editor_scale
	
	_layout_current_bot_element += 1
	return lower_elements_start + Vector2(0, between_elements * (_layout_current_bot_element - 1))

func get_active_list() -> AutoPlaySuiteActionList:
	if current_list == CurrentList.Main:
		return action_list
	else:
		return post_action_list

func _on_action_list_item_selected():
	var list_to_use = get_active_list()
	
	var selected = list_to_use.currently_selected
	var action_resource : AutoPlaySuiteActionResource = list_to_use.backing_dictionary[selected]
	signal_on_action_list_item_selected.emit(action_resource)

func _on_selected_action_id_changed(new_id : String):
	get_active_list().update_display_text_of_selected_index()

func _save_test(path : String = "") -> bool:
	if file_dialog != null:
		return false
	signal_on_before_test_save.emit()

	_sync_current_test_to_list()
	if !_print_validation_errors():
		return false
	
	if path == "":
		if current_file_path == "":
			_save_test_as()
			return false
		path = current_file_path
	
	if path.begins_with("u"):
		path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	
	current_file_path = path
	
	var create : bool = current_test.test_uid == ""
	
	current_test.take_over_path(path)
	var save_error := ResourceSaver.save(current_test, path)
	if save_error != OK:
		printerr("Failed to save test to '%s': error %d" % [path, save_error])
		return false
	
	var uid : int = ResourceSaver.get_resource_id_for_path(path)
	var uid_string : String = ResourceUID.id_to_text(uid)
	current_test.test_uid = uid_string
	
	if create:
		save_error = ResourceSaver.save(current_test, path) # Save again to store UID
		if save_error != OK:
			printerr("Failed to store the test UID in '%s': error %d" % [path, save_error])
			return false
	
	signal_on_current_test_saved.emit(uid_string)
	return true

func _save_test_as():
	signal_on_before_test_save.emit()
	_sync_current_test_to_list()
	if !_print_validation_errors():
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

func _print_validation_errors() -> bool:
	var errors := current_test.get_validation_errors()
	for error in errors:
		printerr("Cannot save test '%s': %s" % [current_test.test_name, error])
	return errors.is_empty()

func _save_file_chosen(path : String):
	file_dialog = null
	_save_test(path)

func _sync_current_test_to_list(action_was_modified : bool = false):
	if currently_setting_new_test:
		return
	
	var all_actions : Array = action_list.get_all_items()
	var all_post_actions : Array = post_action_list.get_all_items()
	var list_was_modified := current_test.actions != all_actions || current_test.post_actions != all_post_actions
	if list_was_modified:
		current_test.actions.assign(all_actions)
		current_test.post_actions.assign(all_post_actions)
	if list_was_modified || action_was_modified:
		signal_on_current_test_modified.emit(current_test)

func new_test():
	signal_on_before_test_change.emit()
	currently_setting_new_test = true
	current_file_path = ""
	current_test = AutoPlaySuiteTestResource.new()
	premature_end_is_error.set_pressed_no_signal(current_test.premature_end_is_error)
	var test_name : String = "test #"
	for n in 4:
		test_name += str(randi_range(0,9)) 
	test_name_field.text = test_name
	current_test.test_name = test_name
	action_list.empty_list()
	action_list.add_default_entry(0)
	
	post_action_list.empty_list()
	currently_setting_new_test = false
	
	
func set_current_test(new_test : AutoPlaySuiteTestResource):
	signal_on_before_test_change.emit()
	currently_setting_new_test = true
	current_test = new_test
	test_name_field.text = current_test.test_name
	premature_end_is_error.set_pressed_no_signal(current_test.premature_end_is_error)
	action_list.empty_list()
	for action in current_test.actions:
		action_list.add_and_bind_item(action.action_id, action)	
	post_action_list.empty_list()
	for action in current_test.post_actions:
		post_action_list.add_and_bind_item(action.action_id, action)	
	currently_setting_new_test = false

func _file_dialog_canceled():
	file_dialog = null

func _set_list_to_main_actions():
	signal_on_before_action_context_change.emit()
	current_list = CurrentList.Main
	action_list.visible = true
	post_action_list.visible = false
	main_actions_button.disabled = true
	post_actions_button.disabled = false
	signal_on_action_list_changed.emit()

func _set_list_to_post_actions():
	signal_on_before_action_context_change.emit()
	current_list = CurrentList.Post
	action_list.visible = false
	post_action_list.visible = true
	main_actions_button.disabled = false
	post_actions_button.disabled = true
	signal_on_action_list_changed.emit()

func deselect_all():
	action_list.deselect_all()
	post_action_list.deselect_all()

func _test_name_field_changed(new_name : String):
	current_test.test_name = new_name
	signal_on_test_name_changed.emit(new_name)
	if !currently_setting_new_test:
		signal_on_current_test_modified.emit(current_test)

func _set_file_dialog_size_and_position():
	file_dialog.min_size = Vector2(600, 400) * AutoPlaySuite._get_plugin_singleton().editor_scale
	file_dialog.position = global_position

func handle_input(event: InputEvent) -> void:
	if current_list == CurrentList.Main:
		action_list.handle_input(event)
	else:
		post_action_list.handle_input(event)

func set_testing_in_progress(in_progress : bool) -> void:
	test_name_field.editable = !in_progress
	premature_end_is_error.disabled = in_progress
	main_actions_button.disabled = in_progress || current_list == CurrentList.Main
	post_actions_button.disabled = in_progress || current_list == CurrentList.Post
	save_test_button.disabled = in_progress
	save_test_as_button.disabled = in_progress
	action_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_progress else Control.MOUSE_FILTER_STOP
	post_action_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_progress else Control.MOUSE_FILTER_STOP

func _toggled_premature_end_is_error(on : bool):
	current_test.premature_end_is_error = on
	if !currently_setting_new_test:
		signal_on_current_test_modified.emit(current_test)
