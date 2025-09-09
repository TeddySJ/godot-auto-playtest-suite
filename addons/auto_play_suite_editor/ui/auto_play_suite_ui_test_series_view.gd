extends Control
class_name AutoPlaySuiteUiTestSeriesView

var base_panel_container : PanelContainer
var hbox_container : HBoxContainer
var test_button_list : Array[Button]

var underlying_dictionary : Dictionary[Button, AutoPlaySuiteTestResource]

func _ready() -> void:
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	base_panel_container = PanelContainer.new()
	base_panel_container.position = Vector2(0, 30) * ed_scale
	base_panel_container.custom_minimum_size = Vector2(custom_minimum_size.x * 0.6, 50)
	add_child(base_panel_container)
	var scroll_container := ScrollContainer.new()
	base_panel_container.add_child(scroll_container)
	hbox_container = HBoxContainer.new()
	scroll_container.add_child(hbox_container)
	
	var resource : AutoPlaySuiteTestResource = AutoPlaySuiteTestResource.new()
	resource.test_name = "Test 1"
	add_button(resource)
	
	resource = AutoPlaySuiteTestResource.new()
	resource.test_name = "Test 24"
	add_button(resource)

	resource = AutoPlaySuiteTestResource.new()
	resource.test_name = "Test Apa"
	add_button(resource)
	add_button(resource)
	add_button(resource)
	add_button(resource)
	add_button(resource)
	add_button(resource)
	add_button(resource)

func add_button(test_resource : AutoPlaySuiteTestResource):
	var button := Button.new()
	button.text = test_resource.test_name
	test_button_list.append(button)
	underlying_dictionary[button] = test_resource
	button.focus_mode = Control.FOCUS_NONE
	hbox_container.add_child(button)

func clear():
	for button in test_button_list:
		button.queue_free()
	test_button_list.clear()
	underlying_dictionary.clear()
	
