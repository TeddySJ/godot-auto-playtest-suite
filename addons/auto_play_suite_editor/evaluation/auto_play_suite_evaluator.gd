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

func _exit_tree() -> void:
	for c_name in CreatedEvaluators.keys():
		if CreatedEvaluators[c_name] == self:
			CreatedEvaluators.erase(c_name)

func setup():
	pass

func _process(delta: float) -> void:
	pass

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	pass

static func log_failed_evaluation(data):
	EngineDebugger.send_message("aps:logging", [OS.get_environment("AutoTestRunToken"), "Default Logger", "Failed Evaluation", str(failed_evaluations), data])
	failed_evaluations += 1
	AutoPlaySuiteTestRunner.failed_evaluation_encountered()

static func get_evaluator_by_class_name(c_name : String) -> AutoPlaySuiteEvaluator:
	var registry_key := _get_registry_key(c_name)
	var evaluator : AutoPlaySuiteEvaluator = CreatedEvaluators.get(registry_key)
	if !is_instance_valid(evaluator) || evaluator.is_queued_for_deletion():
		CreatedEvaluators.erase(registry_key)
		printerr("Tried to find a evaluator that hasn't been instantiated: ", c_name)
		return null
	return evaluator

static func instantiate_by_class_name(c_name: String) -> AutoPlaySuiteEvaluator:
	var real_c_name := _get_registry_key(c_name)
	var existing_evaluator : AutoPlaySuiteEvaluator = CreatedEvaluators.get(real_c_name)
	if is_instance_valid(existing_evaluator) && !existing_evaluator.is_queued_for_deletion():
		printerr("Tried instancing two evaluators of the class ", c_name, "! There can only be one per evaluator type.")
		return null
	CreatedEvaluators.erase(real_c_name)
	
	for entry in ProjectSettings.get_global_class_list():
		if entry["class"] == real_c_name:
			var script: Script = load(entry["path"])
			var instance = script.new()
			if instance is AutoPlaySuiteEvaluator:
				CreatedEvaluators[real_c_name] = instance
				return instance
			else:
				printerr("Tried instancing the class ", real_c_name, " but it was not present in the global class list!")
	return null

static func _get_registry_key(c_name : String) -> String:
	if c_name.begins_with("AutoPlaySuiteCustomEvaluator_"):
		return c_name
	return str("AutoPlaySuiteCustomEvaluator_", c_name)

static func clear_created_evaluators() -> void:
	var evaluators := CreatedEvaluators.values()
	CreatedEvaluators.clear()
	for evaluator in evaluators:
		if is_instance_valid(evaluator) && !evaluator.is_queued_for_deletion():
			evaluator.queue_free()
	failed_evaluations = 0
