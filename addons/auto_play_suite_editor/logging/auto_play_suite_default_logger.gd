extends AutoPlaySuiteLogger
class_name AutoPlaySuiteDefaultLogger

func setup():
	forward_output_to_editor = true
	logger_name = "Default Logger"

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	if action_resource.float_var == 0:
		write_as_entry("Jaha", "Japp")
	else:
		write_as_entry("Nehe", "Nepp")
	
