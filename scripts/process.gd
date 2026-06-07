extends MarginContainer

signal process_killed(process : Dictionary)

@onready var channel_and_playlist_label := %ChannelAndPlaylistLabel
@onready var process_type_label := %ProcessTypeLabel
@onready var status_label := %StatusLabel
@onready var kill_button := %KillButton
@onready var kill_confirmation_dialog := $KillConfirmationDialog

var process := {}:
	set(value):
		process = value
		
		if channel_and_playlist_label:
			channel_and_playlist_label.text = process.playlist.channel + ": " + process.playlist.name
		
		if process_type_label:
			process_type_label.text = process.name
		
		if status_label:
			var text_color = status_colors[process.status]
			status_label.push_color(text_color)
			status_label.add_text(status_messages[process.status])
			status_label.pop()
		
		var killable_states = [ProcessQueue.ProcessState.QUEUED, ProcessQueue.ProcessState.IN_PROGRESS]
		kill_button.disabled = ! killable_states.has(process.status)

var status_colors := {
	ProcessQueue.ProcessState.QUEUED: Color.AQUA,
	ProcessQueue.ProcessState.IN_PROGRESS: Color.YELLOW,
	ProcessQueue.ProcessState.COMPLETE: Color.GREEN,
	ProcessQueue.ProcessState.ERRORED: Color.ORANGE,
	ProcessQueue.ProcessState.KILLED: Color.RED,
}

var status_messages := {
	ProcessQueue.ProcessState.QUEUED: "QUEUED",
	ProcessQueue.ProcessState.IN_PROGRESS: "IN PROGRESS",
	ProcessQueue.ProcessState.COMPLETE: "COMPLETE",
	ProcessQueue.ProcessState.ERRORED: "ERRORED",
	ProcessQueue.ProcessState.KILLED: "KILLED",
}


func _on_kill_button_button_up():
	kill_confirmation_dialog.dialog_text = "Are you sure you want to kill the process %s (%d)" % [process.name, process.pid]
	kill_confirmation_dialog.visible = true


func _on_kill_confirmation_dialog_confirmed():
	process_killed.emit(process)
