extends AutoPlaySuiteLogger
class_name AutoPlaySuiteDefaultLogger

static var Singleton : AutoPlaySuiteDefaultLogger

func setup():
	if is_instance_valid(Singleton) && !Singleton.is_queued_for_deletion():
		queue_free()
		return
	
	Singleton = self
	forward_output_to_editor = true
	logger_name = "Default Logger"

func _exit_tree() -> void:
	if Singleton == self:
		Singleton = null
	super._exit_tree()

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	if action_resource.float_var == 0:
		write_as_entry("Jaha", "Japp")
	else:
		write_as_entry("Nehe", "Nepp")
	
