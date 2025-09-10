extends AutoPlaySuiteLogger
class_name AutoPlaySuiteCustomLogger_AutoLog

static var Singleton : AutoPlaySuiteCustomLogger_AutoLog = null

func setup():
	Singleton = self
	forward_output_to_editor = true
	logger_name = "Autoplay Log"
	write_to_output("Created Logger!")
