extends Node
class_name AutoPlaySuiteLogger

var forward_output_to_editor : bool = false

var dictionary_log : Dictionary[String, Variant]
var output_log : Array[String]

var logger_name : String = "[Undefined Logger]"

func _ready() -> void:
	setup()

func setup():
	pass

func _process(delta: float) -> void:
	pass

func _on_auto_play_action(resource):
	pass
	
func write_to_output(string):
	output_log.append(string)
	if forward_output_to_editor:
		print(string)
	
	EngineDebugger.send_message("aps:logging", [logger_name, "Output Stream", string])

func write_as_entry(key : String, data):
	dictionary_log[key] = data

func log_to_list_entry(key : String, data, also_to_output : bool):
	var array : Array = dictionary_log.get_or_add(key, [])
	array.append(data)
	if also_to_output:
		write_to_output(data)

static func instantiate_by_class_name(c_name: String) -> Object:
	for entry in ProjectSettings.get_global_class_list():
		if entry["class"] == c_name:
			var script: Script = load(entry["path"])
			var instance = script.new()
			if instance is AutoPlaySuiteLogger:
				return instance
			else:
				printerr("Tried instancing the class ", c_name, " but it was not present in the global class list!")
	return null
