@tool
extends EditorDebuggerPlugin

func _has_capture(capture):
		return capture == "aps"

func _capture(message: String, data: Array, session_id: int) -> bool:
	if message == "aps:logging":
		AutoPlaySuite.Singleton._logger_message_received(data, session_id)
		return true
	elif message == "aps:system":
		AutoPlaySuite.Singleton._system_message_received(data, session_id)
		return true
	
	return false

func _setup_session(session_id):
	# Add a new tab in the debugger session UI containing a label.
	var label = Label.new()
	label.name = "Example plugin" # Will be used as the tab title.
	label.text = "Example plugin"
	var session = get_session(session_id)
	AutoPlaySuite.Singleton._debugger_session_setup(session_id, session)
	# Listens to the session started and stopped signals.
	session.started.connect(AutoPlaySuite.Singleton._debugger_session_started.bind(session_id))
	session.stopped.connect(AutoPlaySuite.Singleton._debugger_session_stopped.bind(session_id))
	session.add_session_tab(label)
