extends Window

signal download_clicked(start_index : int, end_index : int)

# TODO Give focus when made visible
@onready var start_input := %StartInput
@onready var end_input := %EndInput

var start_index := "-1"
var end_index := "-1"

var playlist : Dictionary:
	set(value):
		playlist = value
		# FIXME Changing our text after the fact like this is messing with the window positioning
		title = "Download playlist %s" % playlist.name

var console_signal_bus : ConsoleSignalBus


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]
	_reset_indices()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		visible = false


func _reset_indices() -> void:
	start_index = "-1"
	start_input.text = "-1"
	end_index = "-1"
	end_input.text = "-1"


func _on_start_input_text_changed(new_text: String) -> void:
	start_index = new_text


func _on_end_input_text_changed(new_text: String) -> void:
	end_index = new_text


func _on_button_button_up() -> void:
	_submit_form()


func _on_text_submitted(_new_text : String) -> void:
	_submit_form()


func _submit_form() -> void:
	# FIXME Figure this shit out
	if start_index == "" and end_index == "":
		download_clicked.emit(start_index, end_index)
	
	if ! start_index.is_valid_int() or ! end_index.is_valid_int():
		if ! start_index.is_valid_int():
			console_signal_bus.add_error("Invalid start index value given: %s" % start_index)
		if ! end_index.is_valid_int():
			console_signal_bus.add_error("Invalid end index value given: %s" % end_index)
		return
	
	var start = start_index.to_int() if start_index != "" else null
	var end = end_index.to_int() if end_index != "" else null
	
	if end < start:
		console_signal_bus.add_error("End index must be greater than start index: %s to %s is invalid" % [start_index, end_index])
		return
	
	download_clicked.emit(start, end)


func _on_visibility_changed() -> void:
	if visible:
		_reset_indices()
		start_input.grab_focus.call_deferred()


func _on_start_input_focus_entered() -> void:
	start_input.select_all()


func _on_end_input_focus_entered() -> void:
	end_input.select_all()
