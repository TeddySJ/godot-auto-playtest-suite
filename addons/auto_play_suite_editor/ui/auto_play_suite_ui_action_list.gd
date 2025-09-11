extends ReorderableTree
class_name AutoPlaySuiteActionList

signal signal_on_list_changed

var mouse_is_over : bool = false

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_NONE
	allow_rmb_select = true
	drop_mode_flags = DropModeFlags.DROP_MODE_INBETWEEN
	select_mode = Tree.SELECT_MULTI
	signal_on_item_added_and_bound.connect(_emit_list_changed)
	signal_on_item_order_changed.connect(_emit_list_changed)
	signal_on_item_removed.connect(_emit_list_changed)
	mouse_entered.connect(set_mouse_over.bind(true))
	mouse_exited.connect(set_mouse_over.bind(false))

func set_mouse_over(is_over):
	mouse_is_over = is_over

func empty_list():
	clear()
	backing_dictionary.clear()
	root = create_item()

func _emit_list_changed():
	signal_on_list_changed.emit()

func update_display_text_of_selected_index():
	last_selected.set_text(0, backing_dictionary[last_selected].action_id)

func _update_display_text_at_index(index : int):
	pass

func _create_right_click_thing():
	var popup : PopupMenu = PopupMenu.new()
	
	var selection : Array = get_all_selected()
	var item_count : int = selection.size()
	
	if item_count == 0:
		if root.get_child_count() == 0:
			popup.add_item("Add Entry", 0)
		else:
			return
	
	if item_count == 1:
		popup.add_item("Add Entry Above", 1)
		popup.add_item("Add Entry Below", 2)
		popup.add_item("Delete Entry", 3)
	elif item_count > 1:
		popup.add_item("Delete Entries", 4)
		
	popup.id_pressed.connect(_on_action_list_popup_pressed)
	add_child(popup)
	popup.position = get_global_mouse_position()
	
	AutoPlaySuite.set_and_show_popup(popup)

func _on_action_list_popup_pressed(id):
	if id == 0: # Add First Item
		_add_default_entry(0)
	elif id == 1 || id == 2: # Add above / below
		if last_selected == null:
			return
		
		var current_pos : int = last_selected.get_index()
		_add_default_entry(current_pos + (1 if id == 2 else 0))
	elif id == 3: # Delete entry
		if last_selected == null:
			return
		
		remove_item(last_selected)
		last_selected = null
	elif id == 4: # Delete multiple entries
		var selection : Array[TreeItem] = get_all_selected()
		for item in selection:
			remove_item(item)

func _add_default_entry(at_index : int):
	at_index = clamp(at_index, 0, get_item_count())
	add_and_bind_item("New Entry", AutoPlaySuiteActionResource.CreateEmpty(), at_index)

func handle_input(event: InputEvent) -> void:
	# Keyboard input
	
	# Mouse input
	if !mouse_is_over:
		return
	
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_create_right_click_thing()
