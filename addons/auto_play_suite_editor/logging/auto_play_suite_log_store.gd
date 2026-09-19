extends RefCounted
class_name AutoPlaySuiteLogStore

var log_dictionary := {}  # Dictionary[String, Dictionary]
var failed_test_keys : Dictionary[String, bool] = {}
var failed_evaluation_dictionary : Dictionary[String, Dictionary] = {}

static func get_shared() -> AutoPlaySuiteLogStore:
	if !Engine.is_editor_hint():
		return AutoPlaySuiteLogStore.new()
	
	var root := EditorInterface.get_base_control()
	if root.has_meta("APS_LOG_STORE"):
		return root.get_meta("APS_LOG_STORE")
	var s := AutoPlaySuiteLogStore.new()
	root.set_meta("APS_LOG_STORE", s)
	return s

func handle_debugger_message(data: Array, test_key : String):
	if test_key.is_empty():
		printerr("Received an Auto Play Suite log message without a test identity.")
		return
	var target : String = data[1]
	if target == "Failed Evaluation":
		failed_test_keys[test_key] = true
		var failed_eval_dict : Dictionary = failed_evaluation_dictionary.get_or_add(test_key, {})
		var key : String = data[2]
		failed_eval_dict[key] = data[3]
		return

	var main_dict : Dictionary = log_dictionary.get_or_add(test_key, {})
	var dict : Dictionary = main_dict.get_or_add(data[0], {})
	if target == "Output Stream":
		var arr : Array = dict.get_or_add("Output Stream", [])
		arr.append(data[2])
	elif target == "Add Data":
		var key : String = data[2]
		var arr : Array = dict.get_or_add(key, [])
		arr.append(data[3])
	elif target == "Set Data":
		var key : String = data[2]
		dict[key] = data[3]
func print_all_logs():
	var all_log_data := get_all_log_data()
	print("Dict Size: ", all_log_data.size())
	print(all_log_data)
	
func clear_logs():
	log_dictionary.clear()
	failed_test_keys.clear()
	failed_evaluation_dictionary.clear()

func has_failed_evaluations(test_key : String) -> bool:
	return failed_test_keys.get(test_key, false)

func has_log_data(test_key : String) -> bool:
	return log_dictionary.has(test_key) || failed_evaluation_dictionary.has(test_key)

func get_log_data(test_key : String) -> Dictionary:
	var combined_log : Dictionary = log_dictionary.get(test_key, {}).duplicate(true)
	if !failed_evaluation_dictionary.has(test_key):
		return combined_log

	var section_name := "Failed Evaluations"
	while combined_log.has(section_name):
		section_name += " (Auto Play Suite)"
	combined_log[section_name] = failed_evaluation_dictionary[test_key].duplicate(true)
	return combined_log

func get_all_log_data() -> Dictionary:
	var combined_logs : Dictionary = {}
	for test_key : String in log_dictionary:
		combined_logs[test_key] = get_log_data(test_key)
	for test_key : String in failed_evaluation_dictionary:
		if !combined_logs.has(test_key):
			combined_logs[test_key] = get_log_data(test_key)
	return combined_logs
