extends AutoPlaySuiteEvaluator
class_name AutoPlaySuiteCustomEvaluator_GameOfLife

static var Singleton : AutoPlaySuiteCustomEvaluator_GameOfLife = null

func setup():
	Singleton = self
	forward_output_to_editor = true
	evaluator_name = "GoL Evaluator"
	
	AutoPlaySuiteLogger.get_default_logger().write_to_output(str("Created Evaluator: ", evaluator_name))

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	var strings := action_resource.string_var.split(":")
	var instr_id : String = strings[1]
	if instr_id == "KimSkaHaVaritMed":
		if Game.Singleton.unused_names.has("Kim"):
			log_failed_evaluation("Evaluation Failed: Kim has not been added to the game!")
		
