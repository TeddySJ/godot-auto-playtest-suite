extends Node
class_name AutoPlaySuiteLogger

static var CreatedLoggers : Dictionary[String, AutoPlaySuiteLogger]

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

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	pass
	
func write_to_output(string):
	output_log.append(string)
	if forward_output_to_editor:
		print(string)
	
	EngineDebugger.send_message("aps:logging", [logger_name, "Output Stream", string])

func write_as_entry(key : String, data):
	EngineDebugger.send_message("aps:logging", [logger_name, "Set Data", key, data])

func log_to_list_entry(key : String, data, also_to_output : bool):
	var array : Array = dictionary_log.get_or_add(key, [])
	array.append(data)
	write_as_entry(key, array)
	if also_to_output:
		write_to_output(data)

static func get_default_logger() -> AutoPlaySuiteDefaultLogger:
	return AutoPlaySuiteDefaultLogger.Singleton

static func get_logger_by_class_name(c_name : String) -> Object:
	if !CreatedLoggers.has(c_name):
		printerr("Tried to find a logger that hasn't been instantiated: ", c_name)
		return null
	return CreatedLoggers[c_name]

static func instantiate_by_class_name(c_name: String) -> Object:
	if CreatedLoggers.has(c_name):
		printerr("Tried instancing two loggers of the class ", c_name, "! There can only be one per logger type.")
		return
	
	for entry in ProjectSettings.get_global_class_list():
		if entry["class"] == c_name:
			var script: Script = load(entry["path"])
			var instance = script.new()
			if instance is AutoPlaySuiteLogger:
				CreatedLoggers[c_name] = instance
				return instance
			else:
				printerr("Tried instancing the class ", c_name, " but it was not present in the global class list!")
	return null
