extends MarginContainer

signal process_killed(process : Process)

@onready var is_child_process_icon := %IsChildProcessIcon
@onready var channel_and_playlist_label := %ChannelAndPlaylistLabel
@onready var process_type_label := %ProcessTypeLabel
@onready var status_label := %StatusLabel
@onready var kill_button := %KillButton
@onready var kill_confirmation_dialog := $KillConfirmationDialog

var process : Process:
	set(value):
		process = value
		
		if channel_and_playlist_label:
			channel_and_playlist_label.text = process.playlist.channel + ": " + process.playlist.name
		
		if process_type_label:
			process_type_label.text = process.process_name
		
		if status_label:
			var text_color = status_colors[process.status]
			status_label.push_color(text_color)
			status_label.add_text(status_messages[process.status])
			status_label.pop()
		
		var killable_states = [Process.ProcessState.QUEUED, Process.ProcessState.IN_PROGRESS]
		kill_button.disabled = process.killable and ! killable_states.has(process.status)
		
		is_child_process_icon.visible = process.parent_process != null

var status_colors := {
	Process.ProcessState.QUEUED: Color.AQUA,
	Process.ProcessState.IN_PROGRESS: Color.YELLOW,
	Process.ProcessState.COMPLETE: Color.GREEN,
	Process.ProcessState.ERRORED: Color.ORANGE,
	Process.ProcessState.KILLED: Color.RED,
}

var status_messages := {
	Process.ProcessState.QUEUED: "QUEUED",
	Process.ProcessState.IN_PROGRESS: "IN PROGRESS",
	Process.ProcessState.COMPLETE: "COMPLETE",
	Process.ProcessState.ERRORED: "ERRORED",
	Process.ProcessState.KILLED: "KILLED",
}


func _on_kill_button_button_up():
	kill_confirmation_dialog.dialog_text = "Are you sure you want to kill the process %s (%d)" % [process.name, process.pid]
	kill_confirmation_dialog.visible = true


func _on_kill_confirmation_dialog_confirmed():
	process_killed.emit(process)
