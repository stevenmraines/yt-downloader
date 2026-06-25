extends MarginContainer

signal process_killed(process : Process)

@onready var is_child_process_icon := %IsChildProcessIcon
@onready var parent_labels_container := %ParentLabelsContainer
@onready var channel_and_playlist_label := %ChannelAndPlaylistLabel
@onready var process_type_label := %ProcessTypeLabel
@onready var child_process_type_label := %ChildProcessTypeLabel
@onready var status_label := %StatusLabel
@onready var kill_button := %KillButton
@onready var kill_confirmation_dialog := $KillConfirmationDialog

var process : Process:
	set(value):
		process = value
		
		channel_and_playlist_label.text = process.playlist.channel + ": " + process.playlist.name \
			if process.playlist.has("channel") else "N/A"
		process_type_label.text = process.process_name
		child_process_type_label.text = process.process_name
		
		var text_color = status_colors[process.status]
		status_label.push_color(text_color)
		status_label.add_text(status_messages[process.status])
		status_label.pop()
		
		var killable_states = [Process.ProcessState.QUEUED, Process.ProcessState.IN_PROGRESS]
		kill_button.disabled = ! process.killable or ! killable_states.has(process.status)
		
		is_child_process_icon.visible = process.parent_process != null
		parent_labels_container.visible = process.parent_process == null
		child_process_type_label.visible = process.parent_process != null

var status_colors := {
	Process.ProcessState.QUEUED: Color.AQUA,
	Process.ProcessState.IN_PROGRESS: Color.YELLOW,
	Process.ProcessState.COMPLETE: Color.GREEN,
	Process.ProcessState.FAILED: Color.ORANGE,
	Process.ProcessState.KILLED: Color.RED,
	Process.ProcessState.SKIPPED: Color.VIOLET,
}

var status_messages := {
	Process.ProcessState.QUEUED: "QUEUED",
	Process.ProcessState.IN_PROGRESS: "IN PROGRESS",
	Process.ProcessState.COMPLETE: "COMPLETE",
	Process.ProcessState.FAILED: "FAILED",
	Process.ProcessState.KILLED: "KILLED",
	Process.ProcessState.SKIPPED: "SKIPPED",
}


func _on_kill_button_button_up():
	kill_confirmation_dialog.dialog_text = "Are you sure you want to kill the process %s (%d)" % [process.name, process.pid]
	kill_confirmation_dialog.visible = true


func _on_kill_confirmation_dialog_confirmed():
	process_killed.emit(process)
