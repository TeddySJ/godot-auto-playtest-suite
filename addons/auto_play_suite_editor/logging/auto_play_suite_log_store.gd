extends RefCounted
class_name AutoPlaySuiteLogStore

var log_dictionary := {}  # Dictionary[String, Dictionary]

static func get_shared() -> AutoPlaySuiteLogStore:
	if !Engine.is_editor_hint():
		return AutoPlaySuiteLogStore.new()
	
	var root := EditorInterface.get_base_control()
	if root.has_meta("APS_LOG_STORE"):
		return root.get_meta("APS_LOG_STORE")
	var s := AutoPlaySuiteLogStore.new()
	root.set_meta("APS_LOG_STORE", s)
	return s

func handle_debugger_message(data: Array):
	var main_dict : Dictionary = log_dictionary.get_or_add(AutoPlaySuite._get_plugin_singleton().currently_running_test.test_name, {})
	
	var dict : Dictionary = main_dict.get_or_add(data[0], {})
	
	var target : String = data[1]
	if target == "Output Stream":
		var arr : Array = dict.get_or_add("Output Stream", [])
		arr.append(data[2])
	elif target == "Add Data":
		var key : String = data[2]
		var arr : Array = dict.get_or_add(key, [])
		arr.append(data[3])
	elif target == "Set Data":
		var key : String = data[2]
		var arr : Array = dict.get_or_add(key, [])
		arr.append(data[3])
	
	print("Dict Size: ", log_dictionary.size())

func print_all_logs():
	print("Dict Size: ", log_dictionary.size())
	print(log_dictionary)
	
func clear_logs():
	log_dictionary.clear()
