@tool
extends Control
class_name AutoTestingSuite

var action_list : AutoPlaySuiteActionList
var action_view : AutoPlaySuiteUiActionView

var run_all_button : Button

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
	action_list = AutoPlaySuiteActionList.new()
	add_child(action_list)
	
	action_list.position = Vector2(100,100)
	action_list.custom_minimum_size.x = 250
	action_list.custom_minimum_size.y = 300
	
	action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	
	action_list.add_and_bind_item("Ett", AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "jamen de string"))
	action_list.add_and_bind_item("Två", AutoPlaySuiteActionResource.Create(&"[Debug] Print Float", 1, "den här texten syns inte!"))
	action_list.add_and_bind_item("Tre", AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "en till string!"))
	
	action_view = AutoPlaySuiteUiActionView.new()
	add_child(action_view)
	action_view.position = Vector2(400, 100)
	action_view._add_drop_down_item(&"[UNSET]")
	action_view._fill_drop_down(possible_actions.keys())
	action_view.run_action_button.pressed.connect(_run_selected_action)
	
	run_all_button = Button.new()
	run_all_button.position = Vector2(100, action_list.position.y + action_list.custom_minimum_size.y + 50)
	run_all_button.text = "Run All"
	add_child(run_all_button)
	run_all_button.pressed.connect(_run_all_actions)
	
	if is_in_editor:
		_setup_in_editor()

func _setup_in_editor():
	pass

func _on_action_list_item_selected():
	var selected = action_list.last_selected
	var action_resource : AutoPlaySuiteActionResource = action_list.backing_dictionary[selected]
	action_view._set_action(action_resource)

func _run_selected_action():
	if action_view.underlying_action != null:
		possible_actions[action_view.underlying_action.action_id].method.call(action_view.underlying_action)

func _run_all_actions():
	var arr := action_list._get_all_items()
	for el : AutoPlaySuiteActionResource in arr:
		possible_actions[el.action_id].method.call(el)
		
	EditorInterface.play_main_scene()

func init_plugin():
	var custom_instructions = load("res://addons/auto_play_suite_editor/custom_instructions/custom_auto_play_instructions.gd").new()
	custom_instructions.hook_into_suite(self)
	print(possible_actions.size())

func _on_save_dialogue() -> void:
	print("Hej!")
	#var dialogue : DialogueResource = DialogueResource.new()
	#dialogue.dialogue_id = "hehe"
	#dialogue.entry_point = "mos"
	#dialogue.nodes = []
	#dialogue.take_over_path("res://testing.tres")
	#dialogue.save_to_file("res://testing.tres")
