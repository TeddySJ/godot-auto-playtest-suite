extends Control
class_name AutoPlaySuiteUiTestSeriesView

var test_series_name_input : LineEdit

var base_panel_container : PanelContainer
var hbox_container : HBoxContainer
var test_button_list : Array[Button]

var underlying_dictionary : Dictionary[Button, AutoPlaySuiteTestResource]

var current_test_series : AutoPlaySuiteTestSeriesResource

func _ready() -> void:
	if current_test_series == null:
		current_test_series = AutoPlaySuiteTestSeriesResource.new()
	
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	test_series_name_input = LineEdit.new()
	test_series_name_input.position = Vector2(20, 0) * ed_scale
	test_series_name_input.custom_minimum_size.x = 300 * ed_scale
	test_series_name_input.text_changed.connect(_test_series_name_changed)
	add_child(test_series_name_input)
	
	var test_series_name_label = Label.new()
	test_series_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	test_series_name_label.text = "Series Name:"
	test_series_name_label.position = test_series_name_input.position + Vector2(-210, 5)  * ed_scale
	test_series_name_label.custom_minimum_size.x = 200 * ed_scale
	add_child(test_series_name_label)
	
	_randomize_test_series_name()
	
	base_panel_container = PanelContainer.new()
	base_panel_container.position = Vector2(0, 35) * ed_scale
	base_panel_container.custom_minimum_size = Vector2(custom_minimum_size.x * 0.6, 50)
	add_child(base_panel_container)
	var scroll_container := ScrollContainer.new()
	base_panel_container.add_child(scroll_container)
	hbox_container = HBoxContainer.new()
	scroll_container.add_child(hbox_container)
	

func _test_series_name_changed(new_text : String):
	current_test_series.test_series_name = new_text

func _randomize_test_series_name():
	var rand_name : String = "Series #"
	for n in 4:
		rand_name += str(randi_range(0, 1))
	test_series_name_input.text = rand_name
	current_test_series.test_series_name = rand_name

func add_button(test_resource : AutoPlaySuiteTestResource):
	var button := Button.new()
	button.text = test_resource.test_name
	test_button_list.append(button)
	underlying_dictionary[button] = test_resource
	button.pressed.connect(func():_test_button_pressed(button))
	button.focus_mode = Control.FOCUS_NONE
	hbox_container.add_child(button)

func _test_button_pressed(button_pressed : Button):
	print("Test name: ", button_pressed.text, " Series name: ", current_test_series.test_series_name)
	pass

func clear():
	for button in test_button_list:
		button.queue_free()
	test_button_list.clear()
	underlying_dictionary.clear()
	
