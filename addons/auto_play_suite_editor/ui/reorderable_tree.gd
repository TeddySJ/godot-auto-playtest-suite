# ReorderableTree.gd
extends Tree
class_name ReorderableTree

var root : TreeItem

var last_selected : TreeItem = null

var backing_dictionary : Dictionary[TreeItem, Variant]

signal signal_on_cell_selected
signal signal_on_item_added_and_bound
signal signal_on_item_removed
signal signal_on_item_order_changed

func add_and_bind_item(text : String, value, at_index : int = -1):
	var new_item = create_item(root, at_index)
	
	new_item.set_text(0, text)
	backing_dictionary[new_item] = value
	signal_on_item_added_and_bound.emit()

func remove_item(to_remove : TreeItem):
	backing_dictionary.erase(to_remove)
	root.remove_child(to_remove)
	signal_on_item_removed.emit()
	
func remove_item_at_index(index : int):
	remove_item(root.get_child(index))

func _ready():
	root = create_item()
	cell_selected.connect(_on_cell_selected)
	hide_root = true

func _get_amount_dragged(dragged_source) -> int:
	if dragged_source == null:
		return 0
	
	var ret : int = 1
	var current = get_next_selected(dragged_source)
	
	while current != dragged_source:
		if current != null:
			ret += 1
		current = get_next_selected(current)
	return ret

func get_top_selected() -> TreeItem:
	return get_next_selected(null)

func get_all_selected() -> Array[TreeItem]:
	var ret : Array[TreeItem] = []
	var current = get_next_selected(null)
	
	while current != null:
		ret.append(current)
		current = get_next_selected(current)
	
	return ret

func get_index_of_tree_item(tree_item) -> int:
	var all_tree_items := root.get_children()
	for n in all_tree_items.size():
		if all_tree_items[n] == tree_item:
			return n
	return -1

func get_index_of_backing_item(backing_item) -> int:
	var all_tree_items := root.get_children()
	for n in all_tree_items.size():
		if backing_dictionary[all_tree_items[n]] == backing_item:
			return n
	return -1

func get_all_items() -> Array:
	var arr := root.get_children()
	var ret : Array = []
	
	for el in arr:
		ret.append(backing_dictionary[el])
	
	return ret

func get_item_count() -> int:
	return backing_dictionary.size()

func _get_drag_data(at_position: Vector2):
	var it := get_item_at_position(at_position)
	print(str(_get_amount_dragged(it)))
	
	if it == null: return null
	var p := Label.new()
	p.text = it.get_text(0)
	set_drag_preview(p)
	return {"from": it}

func _can_drop_data(at_position: Vector2, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("from") and data["from"] is TreeItem

func _drop_data(at_position: Vector2, data):
	var from: TreeItem = data["from"]
	var to := get_item_at_position(at_position)
	if to == null or from == to:
		return
	var section := get_drop_section_at_position(at_position) # -1 = above, 1 = below
	var all_selected = get_all_selected()
	var first_item = all_selected.pop_front()
	if section == -1:
		first_item.move_before(to)
	elif section == 1:
		first_item.move_after(to)
	
	for item in all_selected:
		item.move_after(first_item)
	
	all_selected.erase(first_item)
	signal_on_item_order_changed.emit()

func _on_cell_selected() -> void:
	last_selected = get_selected()
	signal_on_cell_selected.emit()
