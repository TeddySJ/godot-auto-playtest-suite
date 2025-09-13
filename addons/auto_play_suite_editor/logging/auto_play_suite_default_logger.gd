extends AutoPlaySuiteLogger
class_name AutoPlaySuiteDefaultLogger

static var Singleton : AutoPlaySuiteDefaultLogger

func setup():
	if Singleton:
		queue_free()
		return
	
	Singleton = self
	forward_output_to_editor = true
	logger_name = "Default Logger"

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	if action_resource.float_var == 0:
		write_as_entry("Jaha", "Japp")
	else:
		write_as_entry("Nehe", "Nepp")
	
