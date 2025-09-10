extends RefCounted
class_name AutoPlaySuiteInstructionLoader

static var refs : Array = []

static func LoadAllInstructions():
	for entry in ProjectSettings.get_global_class_list():
		var c_name : String = entry["class"]
		if c_name.contains("AutoPlaySuiteInstructionSet"):
			var script: Script = load(entry["path"])
			var instance : RefCounted = script.new()
			
			if instance.has_method(&"hook_into_suite"):
				instance.call(&"hook_into_suite")
				refs.append(instance)
			else:
				printerr("Could not find the expected 'hook_into_suite' method in the class ", c_name, "!")
