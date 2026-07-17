extends Window

signal download_clicked(options : Dictionary)

@onready var start_input := %StartInput
@onready var end_input := %EndInput
@onready var use_archive_file_input := %UseArchiveFileInput
@onready var copy_to_backup_input := %CopyToBackupInput
@onready var copy_to_remote_input := %CopyToRemoteInput
@onready var delete_download_input := %DeleteDownloadInput

var playlist : Dictionary:
	set(value):
		playlist = value
		# FIXME Changing our text after the fact like this is messing with the window positioning
		title = "Download playlist %s" % playlist.name
		_reset()

var console_signal_bus : ConsoleSignalBus

var options := {
	"start_index" : "",
	"end_index" : "",
	"use_archive_file" : true,
	"copy_to_backup": true,
	"copy_to_remote": true,
	"delete_download": true,
}


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		visible = false


func _reset() -> void:
	start_input.text = ""
	end_input.text = ""
	use_archive_file_input.button_pressed = true
	copy_to_backup_input.button_pressed = playlist.backup_upload_path != ""
	copy_to_remote_input.button_pressed = playlist.remote_upload_path != ""
	delete_download_input.button_pressed = playlist.delete_download
	options.start_index = ""
	options.end_index = ""
	options.use_archive_file = true
	options.copy_to_backup = true
	options.copy_to_remote = true
	options.delete_download = true


func _on_button_button_up() -> void:
	_submit_form()


func _on_text_submitted(_new_text : String) -> void:
	_submit_form()


func _submit_form() -> void:
	options.start_index = start_input.text
	options.end_index = end_input.text
	options.use_archive_file = use_archive_file_input.button_pressed
	options.copy_to_backup = copy_to_backup_input.button_pressed
	options.copy_to_remote = copy_to_remote_input.button_pressed
	options.delete_download = delete_download_input.button_pressed
	
	if start_input.text == "" and end_input.text == "":
		download_clicked.emit(options)
		visible = false
		return
	
	if (start_input.text == "" and end_input.text != "") or (start_input.text != "" and end_input.text == ""):
		console_signal_bus.add_error("Invalid start and end index values: %s to %s" % [start_input.text, end_input.text])
		return
	
	# If anything was submitted, validate start and end as ints but emit them as strings
	var start_is_valid_int = start_input.text.is_valid_int()
	var end_is_valid_int = end_input.text.is_valid_int()
	
	if ! start_is_valid_int or ! end_is_valid_int:
		if ! start_is_valid_int:
			console_signal_bus.add_error("Invalid start index value given: %s" % start_input.text)
		if ! end_is_valid_int:
			console_signal_bus.add_error("Invalid end index value given: %s" % end_input.text)
		return
	
	if end_input.text.to_int() < start_input.text.to_int():
		console_signal_bus.add_error("End index must be greater than start index: %s to %s is invalid" % [start_input.text, end_input.text])
		return
	
	download_clicked.emit(options)
	visible = false


func _on_visibility_changed() -> void:
	if visible:
		start_input.grab_focus.call_deferred()
		_reset()


func _on_start_input_focus_entered() -> void:
	start_input.select_all()


func _on_end_input_focus_entered() -> void:
	end_input.select_all()
