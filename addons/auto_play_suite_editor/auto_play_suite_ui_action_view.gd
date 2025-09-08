extends Control
class_name AutoPlaySuiteUiActionView

static var index_pool : int = 0
var backing_dictionary : Dictionary[StringName, int]

var main_panel : Panel
var drop_down : OptionButton
var run_action_button : Button

var float_var_spinbox : SpinBox
var string_var_line_edit : LineEdit
# TODO: Add functionality for the array of strings, possibly via a dropdown as an interface (with add new and remove as buttons)

var underlying_action : AutoPlaySuiteActionResource = null

func _ready() -> void:
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(400, 400)
	add_child(main_panel)
	drop_down = OptionButton.new()
	drop_down.position = Vector2(30, 30)
	drop_down.custom_minimum_size.x = 300
	drop_down.item_selected.connect(_action_id_changed)
	main_panel.add_child(drop_down)
	
	run_action_button = Button.new()
	run_action_button.text = "Run"
	run_action_button.position = Vector2(30, 300)
	main_panel.add_child(run_action_button)
	
	var float_var_pos := Vector2(30, 80)
	
	var label := Label.new()
	label.text = "Float Var:"
	label.position = float_var_pos
	main_panel.add_child(label)
	
	float_var_spinbox = SpinBox.new()
	float_var_spinbox.min_value = -99999999
	float_var_spinbox.max_value = 99999999
	float_var_spinbox.position = float_var_pos + Vector2(100, -4)
	float_var_spinbox.custom_minimum_size.x = 200
	float_var_spinbox.value_changed.connect(_string_var_changed)
	main_panel.add_child(float_var_spinbox)
	
	var string_var_pos := Vector2(30, 140)
	
	label = Label.new()
	label.text = "String Var:"
	label.position = string_var_pos
	main_panel.add_child(label)
	
	string_var_line_edit = LineEdit.new()
	string_var_line_edit.position = string_var_pos + Vector2(100, -4)
	string_var_line_edit.custom_minimum_size.x = 200
	string_var_line_edit.text_changed.connect(_string_var_changed)
	main_panel.add_child(string_var_line_edit)
	
	if underlying_action == null:
		visible = false

func _add_drop_down_item(_name : StringName):
	drop_down.add_item(_name)
	backing_dictionary[_name] = index_pool
	index_pool += 1

func _fill_drop_down(names : Array[StringName]):
	for _name in names:
		_add_drop_down_item(_name)

func _action_id_changed(index : int):
	underlying_action.action_id = drop_down.text

func _string_var_changed(new_text : String):
	underlying_action.string_var = new_text

func _float_var_changed(new_value : float):
	underlying_action.float_var = new_value

func _set_action(action_to_set : AutoPlaySuiteActionResource):
	visible = true
	underlying_action = action_to_set
	_update_text_fields()

func _update_text_fields():
	var drop_down_id : int = backing_dictionary[underlying_action.action_id]
	drop_down.select(drop_down.get_item_index(drop_down_id))
	string_var_line_edit.text = underlying_action.string_var
	float_var_spinbox.value = underlying_action.float_var
