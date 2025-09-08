extends ReorderableTree
class_name AutoPlaySuiteActionList

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_NONE
	allow_rmb_select = true
	drop_mode_flags = DropModeFlags.DROP_MODE_INBETWEEN
	select_mode = Tree.SELECT_MULTI


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
	popup.show()

func _on_action_list_popup_pressed(id):
	if id == 0: # Add First Item
		add_and_bind_item("New Entry", 0, 0)
	elif id == 1 || id == 2: # Add above / below
		if last_selected == null:
			return
		
		var current_pos : int = last_selected.get_index()
		add_and_bind_item("New Entry", 0, current_pos + (1 if id == 2 else 0))
	elif id == 3: # Delete entry
		if last_selected == null:
			return
		
		remove_item(last_selected)
		last_selected = null
	elif id == 4: # Delete multiple entries
		var selection : Array[TreeItem] = get_all_selected()
		for item in selection:
			remove_item(item)

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_create_right_click_thing()
