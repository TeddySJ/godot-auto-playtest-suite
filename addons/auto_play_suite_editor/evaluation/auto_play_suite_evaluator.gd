extends Node
class_name AutoPlaySuiteEvaluator

static var CreatedEvaluators : Dictionary[String, AutoPlaySuiteEvaluator]

var forward_output_to_editor : bool = false

var dictionary_log : Dictionary[String, Variant]
var output_log : Array[String]

var evaluator_name : String = "[Undefined Evaluator]"

static var failed_evaluations : int = 0

func _ready() -> void:
	setup()

func setup():
	pass

func _process(delta: float) -> void:
	pass

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	pass

static func log_failed_evaluation(data):
	EngineDebugger.send_message("aps:logging", ["Default Logger", "Failed Evaluation", str(failed_evaluations), data])
	failed_evaluations += 1

static func get_evaluator_by_class_name(c_name : String) -> Object:
	if !CreatedEvaluators.has(c_name):
		printerr("Tried to find a evaluator that hasn't been instantiated: ", c_name)
		return null
	return CreatedEvaluators[c_name]

static func instantiate_by_class_name(c_name: String) -> Object:
	if CreatedEvaluators.has(c_name):
		printerr("Tried instancing two evaluators of the class ", c_name, "! There can only be one per evaluator type.")
		return
	
	for entry in ProjectSettings.get_global_class_list():
		if entry["class"] == c_name:
			var script: Script = load(entry["path"])
			var instance = script.new()
			if instance is AutoPlaySuiteEvaluator:
				CreatedEvaluators[c_name] = instance
				return instance
			else:
				printerr("Tried instancing the class ", c_name, " but it was not present in the global class list!")
	return null
