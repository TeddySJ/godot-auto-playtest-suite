extends ReorderableTree
class_name AutoPlaySuiteActionList

signal signal_on_list_changed

var mouse_is_over : bool = false

var copied_keys : Array[TreeItem]
var copied_values  : Array[AutoPlaySuiteActionResource]

enum PopupChoice
{
	NULL = 0,
	AddEntry = 10,
	AddEntry_Above,
	AddEntry_Below,
	DuplicateEntries = 20,
	DeleteEntries = 30,
	Cut = 40,
	Copy,
	Paste,
	
}

var popup_choice_to_callable : Dictionary[int, Callable] = { 
	PopupChoice.AddEntry : _add_entry, PopupChoice.AddEntry_Above : _add_entry_above_or_below.bind(false), PopupChoice.AddEntry_Below : _add_entry_above_or_below.bind(true),
	PopupChoice.DuplicateEntries : _duplicate_entries, PopupChoice.DeleteEntries : _delete_entries, 
	PopupChoice.Cut : _cut_entries, PopupChoice.Copy : _copy_entries,PopupChoice.Paste : _paste_entries,  
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
		popup.add_item("Duplicate Entry", PopupChoice.DuplicateEntries)
		popup.add_separator()
		popup.add_item("Delete Entry", PopupChoice.DeleteEntries)
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
	popup_choice_to_callable[id].call()

func _add_entry():
	add_default_entry(0)

func _add_entry_above_or_below(is_below : bool):
	if last_selected == null:
		return

	var current_pos : int = last_selected.get_index()
	add_default_entry(current_pos + (1 if is_below else 0))

func _duplicate_entries():
	var selection : Array[TreeItem] = get_all_selected()
	
	if selection.size() == 0:
		return
	
	var last_index : int = get_index_of_tree_item(selection.back())
	#var items_to_duplicate : Array[AutoPlaySuiteActionResource]
	var sel_size : int = selection.size()
	for n in sel_size:
		#items_to_duplicate.append(backing_dictionary[tree_item])
		var tree_item := selection[sel_size - n - 1]
		var to_duplicate : AutoPlaySuiteActionResource = backing_dictionary[tree_item]
		add_and_bind_item(tree_item.get_text(0), to_duplicate.duplicate(true), last_index + 1)
	
	signal_on_item_order_changed.emit()

func _delete_entries():
	var selection : Array[TreeItem] = get_all_selected()
	for item in selection:
		remove_item(item)

func _cut_entries():
	_copy_entries()
	_delete_entries()

func _copy_entries():
	var list_of_actions : Array = get_all_selected()
	_add_entries_to_buffer(list_of_actions)

func _paste_entries():
	var start_index = get_index_of_tree_item(last_selected)
	for n in copied_keys.size():
		var reverse_index = copied_keys.size() - 1 - n
		add_and_bind_item(copied_keys[reverse_index].get_text(0), copied_values[reverse_index].duplicate(true), start_index + 1)

func _add_entries_to_buffer(entries  : Array):
	copied_keys.clear()
	copied_values.clear()
	
	for entry : TreeItem in entries:
		copied_keys.append(entry)
		copied_values.append(backing_dictionary[entry])

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
