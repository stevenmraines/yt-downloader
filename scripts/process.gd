extends MarginContainer

signal process_killed(process : Dictionary)

@onready var name_label := $HBoxContainer/NameLabel
@onready var status_label := $HBoxContainer/StatusLabel
@onready var kill_button := $HBoxContainer/KillButton
@onready var kill_confirmation_dialog := $KillConfirmationDialog

var process := {}:
	set(value):
		process = value
		
		if name_label:
			name_label.text = process.name
		
		if status_label:
			status_label.add_text("Status: ")
			var text_color = status_colors[process.status]
			status_label.push_color(text_color)
			status_label.add_text(status_messages[process.status])
			status_label.pop()
		
		var killable_states = [ProcessQueue.ProcessState.QUEUED, ProcessQueue.ProcessState.IN_PROGRESS]
		kill_button.disabled = ! killable_states.has(process.status)

var status_colors := {
	ProcessQueue.ProcessState.QUEUED: Color.BLUE,
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
