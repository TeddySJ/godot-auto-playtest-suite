extends Control
class_name AutoPlaySuiteUiActionView

static var index_pool : int = 0
var backing_dictionary : Dictionary[StringName, int]

var main_panel : Panel
var drop_down : OptionButton
var run_action_button : Button

var underlying_action : AutoPlaySuiteActionResource = null

func _ready() -> void:
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(400, 200)
	add_child(main_panel)
	drop_down = OptionButton.new()
	main_panel.add_child(drop_down)
	drop_down.position = Vector2(30, 30)
	
	run_action_button = Button.new()
	run_action_button.text = "Run"
	run_action_button.position = Vector2(30, 100)
	add_child(run_action_button)

func _add_drop_down_item(_name : StringName):
	drop_down.add_item(_name)
	backing_dictionary[_name] = index_pool
	index_pool += 1

func _fill_drop_down(names : Array[StringName]):
	for _name in names:
		_add_drop_down_item(_name)

func _set_action(action_to_set : AutoPlaySuiteActionResource):
	underlying_action = action_to_set
	var drop_down_id : int = backing_dictionary[action_to_set.action_id]
	drop_down.select(drop_down.get_item_index(drop_down_id))
