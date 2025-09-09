@tool
extends EditorDebuggerPlugin

func _capture(message, data, session_id) -> bool:
	if message == "aps:logging":
		AutoPlaySuite.Singleton._logger_message_received(data)
		return true
	
	print("Ostron")
	return false
