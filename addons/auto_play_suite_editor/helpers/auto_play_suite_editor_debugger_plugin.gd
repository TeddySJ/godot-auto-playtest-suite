@tool
extends EditorDebuggerPlugin

func _has_capture(capture):
		return capture == "aps"

func _capture(message: String, data: Array, session_id: int) -> bool:
	if message == "aps:logging":
		AutoPlaySuite.Singleton._logger_message_received(data)
		return true
	
	return false

func _setup_session(session_id):
	# Add a new tab in the debugger session UI containing a label.
	var label = Label.new()
	label.name = "Example plugin" # Will be used as the tab title.
	label.text = "Example plugin"
	var session = get_session(session_id)
	# Listens to the session started and stopped signals.
	session.started.connect(func (): print("Session started"))
	session.stopped.connect(func (): print("Session stopped"))
	session.add_session_tab(label)
