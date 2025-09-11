extends ReorderableTree
class_name AutoPlaySuiteActionList

signal signal_on_list_changed

var mouse_is_over : bool = false

enum PopupChoice
{
	NULL = 0,
	AddEntry = 10,
	AddEntry_Above,
	AddEntry_Below,
	DuplicateEntry = 20,
	DuplicateEntries,
	DeleteEntry = 30,
	DeleteEntries,
	Cut = 40,
	Copy,
	Paste,
	
}

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
			popup.add_item("Add Entry", PopupChoice.AddEntry)
		else:
			return
	
	if item_count == 1:
		popup.add_item("Add Entry Above", PopupChoice.AddEntry_Above)
		popup.add_item("Add Entry Below", PopupChoice.AddEntry_Below)
		popup.add_item("Duplicate Entry", PopupChoice.DuplicateEntry)
		popup.add_separator()
		popup.add_item("Delete Entry", PopupChoice.DeleteEntry)
		popup.add_separator()
		popup.add_item("Cut", PopupChoice.Cut)
		popup.add_item("Copy", PopupChoice.Copy)
		popup.add_item("Paste", PopupChoice.Paste)
	elif item_count > 1:
		popup.add_item("Duplicate Entries", PopupChoice.DuplicateEntries)
		popup.add_separator()
		popup.add_item("Delete Entries", PopupChoice.DeleteEntries)
		popup.add_separator()
		popup.add_item("Cut", PopupChoice.Cut)
		popup.add_item("Copy", PopupChoice.Copy)
		popup.add_item("Paste", PopupChoice.Paste)
		
	popup.id_pressed.connect(_on_action_list_popup_pressed)
	add_child(popup)
	popup.position = get_global_mouse_position()
	
	AutoPlaySuite.set_and_show_popup(popup)

func _on_action_list_popup_pressed(id):
	if id == PopupChoice.AddEntry:
		add_default_entry(0)
	elif id == PopupChoice.AddEntry_Above || id == PopupChoice.AddEntry_Below:
		if last_selected == null:
			return
		
		var current_pos : int = last_selected.get_index()
		add_default_entry(current_pos + (1 if id == PopupChoice.AddEntry_Below else 0))
	elif id == PopupChoice.DeleteEntry: 
		if last_selected == null:
			return
		
		remove_item(last_selected)
		last_selected = null
	elif id == PopupChoice.DeleteEntries:
		var selection : Array[TreeItem] = get_all_selected()
		for item in selection:
			remove_item(item)

func add_default_entry(at_index : int):
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
