extends Node
class_name AutoPlaySuiteLogger

static var CreatedLoggers : Dictionary[String, AutoPlaySuiteLogger]

var forward_output_to_editor : bool = false

var dictionary_log : Dictionary[String, Variant]
var output_log : Array[String]

var logger_name : String = "[Undefined Logger]"

func _ready() -> void:
	setup()

func _exit_tree() -> void:
	for c_name in CreatedLoggers.keys():
		if CreatedLoggers[c_name] == self:
			CreatedLoggers.erase(c_name)

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
	
	EngineDebugger.send_message("aps:logging", [OS.get_environment("AutoTestRunToken"), logger_name, "Output Stream", string])

func write_as_entry(key : String, data):
	EngineDebugger.send_message("aps:logging", [OS.get_environment("AutoTestRunToken"), logger_name, "Set Data", key, data])

func log_to_list_entry(key : String, data, also_to_output : bool):
	var array : Array = dictionary_log.get_or_add(key, [])
	array.append(data)
	write_as_entry(key, array)
	if also_to_output:
		write_to_output(data)

static func get_default_logger() -> AutoPlaySuiteDefaultLogger:
	if !is_instance_valid(AutoPlaySuiteDefaultLogger.Singleton) || AutoPlaySuiteDefaultLogger.Singleton.is_queued_for_deletion():
		AutoPlaySuiteDefaultLogger.Singleton = null
	return AutoPlaySuiteDefaultLogger.Singleton

static func get_logger_by_class_name(c_name : String) -> AutoPlaySuiteLogger:
	var logger : AutoPlaySuiteLogger = CreatedLoggers.get(c_name)
	if !is_instance_valid(logger) || logger.is_queued_for_deletion():
		CreatedLoggers.erase(c_name)
		printerr("Tried to find a logger that hasn't been instantiated: ", c_name)
		return null
	return logger

static func instantiate_by_class_name(c_name: String) -> AutoPlaySuiteLogger:
	var existing_logger : AutoPlaySuiteLogger = CreatedLoggers.get(c_name)
	if is_instance_valid(existing_logger) && !existing_logger.is_queued_for_deletion():
		printerr("Tried instancing two loggers of the class ", c_name, "! There can only be one per logger type.")
		return null
	CreatedLoggers.erase(c_name)
	
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

static func clear_created_loggers() -> void:
	var loggers := CreatedLoggers.values()
	CreatedLoggers.clear()
	for logger in loggers:
		if is_instance_valid(logger) && !logger.is_queued_for_deletion():
			logger.queue_free()
