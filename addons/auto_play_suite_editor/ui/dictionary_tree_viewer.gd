@tool
extends Control
class_name DictTreeViewer

## ————— Config —————
@export var sort_keys := true
@export var containers_collapsed_by_default := false

## Set this to rebuild the view.
@export var data: Dictionary:
	set = set_data, get = get_data

var _tree: Tree

func _ready() -> void:
	_build_tree_node()
	_rebuild()

func _build_tree_node() -> void:
	if _tree: return
	_tree = Tree.new()
	_tree.columns = 2
	_tree.hide_root = true
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.anchors_preset = Control.PRESET_FULL_RECT
	_tree.set_column_titles_visible(true)
	_tree.set_column_title(0, "Key")
	_tree.set_column_title(1, "Value")
	_tree.set_column_expand_ratio(0, 0.5)
	_tree.set_column_expand_ratio(1, 0.5)
	add_child(_tree)

func set_data(d: Dictionary) -> void:
	data = d
	_rebuild()

func get_data() -> Dictionary:
	return data

func clear() -> void:
	data.clear()
	_rebuild()

## Convenience
func expand_all() -> void:
	_for_each_item(func(it: TreeItem): it.collapsed = false)

func collapse_all() -> void:
	_for_each_item(func(it: TreeItem): it.collapsed = true)

func _for_each_item(action: Callable) -> void:
	if not _tree or not _tree.get_root(): return
	_iter_items(_tree.get_root(), action)

func _iter_items(item: TreeItem, action: Callable) -> void:
	if item == null: return
	action.call(item)
	var c := item.get_first_child()
	while c:
		_iter_items(c, action)
		c = c.get_next()

## ————— Build / Populate —————
func _rebuild() -> void:
	if not _tree: return
	_tree.clear()
	var root := _tree.create_item()

	var keys: Array = data.keys()
	if sort_keys:
		keys.sort_custom(func(a, b): return str(a) < str(b))

	for k in keys:
		_add_entry(root, str(k), data[k])

func _add_entry(parent: TreeItem, label: String, v) -> void:
	if v is Dictionary:
		var ti := _branch_item(parent, label, "Object{" + str((v as Dictionary).size()) + "}")
		var keys := (v as Dictionary).keys()
		if sort_keys:
			keys.sort_custom(func(a, b): return str(a) < str(b))
		for kk in keys:
			_add_entry(ti, str(kk), v[kk])

	elif v is Array:
		var arr := v as Array
		var ti := _branch_item(parent, label, "Array[" + str(arr.size()) + "]")
		for i in arr.size():
			_add_entry(ti, "[" + str(i) + "]", arr[i])

	elif _is_packed_array(v):
		var len := _packed_array_len(v)
		var ti := _branch_item(parent, label, _packed_array_name(v) + "[" + str(len) + "]")
		for i in len:
			_add_entry(ti, "[" + str(i) + "]", v[i])

	else:
		var ti := _tree.create_item(parent)
		ti.set_text(0, label)
		ti.set_text(1, _value_to_string(v))
		ti.selectable = true

func _branch_item(parent: TreeItem, label: String, summary: String) -> TreeItem:
	var ti := _tree.create_item(parent)
	ti.set_text(0, label)
	ti.set_text(1, summary)
	ti.collapsed = containers_collapsed_by_default
	ti.selectable = true
	return ti

## ————— Helpers —————
func _value_to_string(v) -> String:
	match typeof(v):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_INT, TYPE_FLOAT:
			return str(v)
		TYPE_STRING:
			return "\"" + (v as String) + "\""
		TYPE_STRING_NAME:
			return "StringName(\"" + String(v) + "\")"
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I, \
		TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_BASIS, TYPE_QUATERNION, TYPE_PLANE, TYPE_AABB, TYPE_RECT2, TYPE_RECT2I:
			return str(v)
		TYPE_COLOR:
			return (v as Color).to_html(true) # #RRGGBBAA
		TYPE_NODE_PATH, TYPE_RID, TYPE_PROJECTION, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_PACKED_BYTE_ARRAY, \
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, \
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, \
		TYPE_PACKED_VECTOR4_ARRAY:
			return str(v)
		TYPE_OBJECT:
			if v is Object:
				var o := v as Object
				if o is Node:
					return "[Object:" + o.get_class() + " \"" + (o as Node).name + "\"]"
				elif o is Resource:
					var res := o as Resource
					return "[Resource:" + res.get_class() + (" \"" + res.resource_path + "\"" if res.resource_path != "" else "") + "]"
				return "[Object:" + o.get_class() + "]"
			return "[Object]"
		_:
			return str(v)

func _is_packed_array(v) -> bool:
	return v is PackedByteArray \
		or v is PackedInt32Array or v is PackedInt64Array \
		or v is PackedFloat32Array or v is PackedFloat64Array \
		or v is PackedStringArray \
		or v is PackedVector2Array or v is PackedVector3Array or v is PackedVector4Array \
		or v is PackedColorArray

func _packed_array_len(v) -> int:
	# All packed arrays implement size()
	return v.size()

func _packed_array_name(v) -> String:
	if v is PackedByteArray: return "PackedByteArray"
	if v is PackedInt32Array: return "PackedInt32Array"
	if v is PackedInt64Array: return "PackedInt64Array"
	if v is PackedFloat32Array: return "PackedFloat32Array"
	if v is PackedFloat64Array: return "PackedFloat64Array"
	if v is PackedStringArray: return "PackedStringArray"
	if v is PackedVector2Array: return "PackedVector2Array"
	if v is PackedVector3Array: return "PackedVector3Array"
	if v is PackedVector4Array: return "PackedVector4Array"
	if v is PackedColorArray: return "PackedColorArray"
	return "PackedArray"
