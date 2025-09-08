@tool
extends Control
class_name AutoTestingSuite

var current_test_series : AutoPlaySuiteTestSeriesResource
var current_test : AutoPlaySuiteTestResource

var action_list : AutoPlaySuiteActionList
var action_view : AutoPlaySuiteUiActionView

var run_test_button : Button
var run_all_button : Button
var save_test_button : Button
var save_test_as_button : Button
var load_test_button : Button

var possible_actions : Dictionary[StringName, InstructionDefinition]

var item_affected_by_popup : TreeItem

var current_context : CurrentContext = CurrentContext.Running
var is_in_editor : bool:
	get:
		return current_context == CurrentContext.InEditor

var should_handle_input : bool:
	get:
		return current_context == CurrentContext.Running || current_context == CurrentContext.InPlugin_HasScreen

enum CurrentContext
{
	InEditor,
	InPlugin_HasScreen,
	InPlugin_DontHaveScreen,
	Running,
}

func _ready() -> void:
	if Engine.is_editor_hint():
		current_context = CurrentContext.InEditor
	setup_ui.call_deferred()

func _on_editor_main_screen_changed(screen_name):
	if screen_name == "AutoTest":
		current_context = CurrentContext.InPlugin_HasScreen
	else:
		current_context = CurrentContext.InPlugin_DontHaveScreen

func _input(event: InputEvent) -> void:
	if !should_handle_input:
		return
	
	if action_list == null:
		return
	
	action_list.handle_input(event)

func setup_ui() -> void:
	if current_context == CurrentContext.Running:
		_setup_in_single_scene()

	action_list = AutoPlaySuiteActionList.new()
	add_child(action_list)
	
	action_list.position = Vector2(100,100)
	action_list.custom_minimum_size.x = 250
	action_list.custom_minimum_size.y = 300
	
	action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "jamen de string"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print Float", 1, "den här texten syns inte!"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "en till string!"))
	
	for action in current_test.actions:
		action_list.add_and_bind_item(action.action_id, action)
	
	action_view = AutoPlaySuiteUiActionView.new()
	add_child(action_view)
	action_view.position = Vector2(400, 100)
	action_view._add_drop_down_item(&"[UNSET]")
	action_view._fill_drop_down(possible_actions.keys())
	action_view.run_action_button.pressed.connect(_run_selected_action)
	
	run_test_button = Button.new()
	run_test_button.position = Vector2(100, action_list.position.y + action_list.custom_minimum_size.y + 50)
	run_test_button.text = "Run Test"
	add_child(run_test_button)
	run_test_button.pressed.connect(_run_current_test)
	
	run_all_button = Button.new()
	run_all_button.position = run_test_button.position + Vector2(100, 0)
	run_all_button.text = "Run All"
	add_child(run_all_button)
	run_all_button.pressed.connect(_run_all_tests)

	save_test_button = Button.new()
	save_test_button.position = Vector2(100, run_all_button.position.y + 50)
	save_test_button.text = "Save Test"
	add_child(save_test_button)
	save_test_button.pressed.connect(_save_test)
	
	save_test_as_button = Button.new()
	save_test_as_button.position = save_test_button.position + Vector2(100, 0)
	save_test_as_button.text = "Save Test As"
	add_child(save_test_as_button)
	save_test_as_button.pressed.connect(_save_test_as)
	
	load_test_button = Button.new()
	load_test_button.position = save_test_button.position + Vector2(0, 50)
	load_test_button.text = "Load Test"
	add_child(load_test_button)
	load_test_button.pressed.connect(_load_test)
	
	if is_in_editor:
		_setup_in_editor()

func _setup_in_single_scene():
	init_plugin()

func _setup_in_editor():
	pass

func _on_action_list_item_selected():
	var selected = action_list.last_selected
	var action_resource : AutoPlaySuiteActionResource = action_list.backing_dictionary[selected]
	action_view._set_action(action_resource)

func _save_test():
	var path : String = "res://testing.tres"
	current_test.take_over_path(path)
	ResourceSaver.save(current_test, path)

func _save_test_as():
	pass

func _load_test():
	pass

func _run_selected_action():
	if action_view.underlying_action != null:
		possible_actions[action_view.underlying_action.action_id].method.call(action_view.underlying_action)

func _run_current_test():
	_save_test()
	
	OS.set_environment("DoAutoTesting", "true")
	OS.set_environment("AutoTestPath", "res://testing.tres")
	
	EditorInterface.play_main_scene()

func _run_all_tests():
	pass

func init_plugin():
	var custom_instructions = load("res://addons/auto_play_suite_editor/custom_instructions/custom_auto_play_instructions.gd").new()
	custom_instructions.hook_into_suite(self)
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	current_test = AutoPlaySuiteTestResource.new()

func _on_save_dialogue() -> void:
	print("Hej!")
	#var dialogue : DialogueResource = DialogueResource.new()
	#dialogue.dialogue_id = "hehe"
	#dialogue.entry_point = "mos"
	#dialogue.nodes = []
	#dialogue.take_over_path("res://testing.tres")
	#dialogue.save_to_file("res://testing.tres")
