extends RefCounted
class_name AutoPlaySuiteInstructionLoader

static var refs : Array = []

static func LoadAllInstructions():
	refs.clear()
	AutoPlaySuiteActionLibrary.clear_library()
	var global_classes := ProjectSettings.get_global_class_list()
	global_classes.sort_custom(_sort_classes_by_name)
	for entry in global_classes:
		var c_name : String = entry["class"]
		if c_name.contains("AutoPlaySuiteInstructionSet"):
			var script: Script = load(entry["path"])
			var instance : RefCounted = script.new()
			
			if instance.has_method(&"hook_into_suite"):
				instance.call(&"hook_into_suite")
				refs.append(instance)
			else:
				printerr("Could not find the expected 'hook_into_suite' method in the class ", c_name, "!")

static func _sort_classes_by_name(a : Dictionary, b : Dictionary) -> bool:
	return String(a["class"]) < String(b["class"])
