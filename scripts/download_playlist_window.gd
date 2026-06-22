extends Window

signal download_clicked(start_index : String, end_index : String)

# TODO Give focus when made visible
@onready var start_input := %StartInput
@onready var end_input := %EndInput

var start_index := ""
var end_index := ""

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
	start_index = ""
	start_input.text = ""
	end_index = ""
	end_input.text = ""


func _on_start_input_text_changed(new_text: String) -> void:
	start_index = new_text


func _on_end_input_text_changed(new_text: String) -> void:
	end_index = new_text


func _on_button_button_up() -> void:
	_submit_form()


func _on_text_submitted(_new_text : String) -> void:
	_submit_form()


func _submit_form() -> void:
	if start_index == "" and end_index == "":
		download_clicked.emit(start_index, end_index)
		return
	
	if (start_index == "" and end_index != "") or (start_index != "" and end_index == ""):
		console_signal_bus.add_error("Invalid start and end index values: %s to %s" % [start_index, end_index])
		return
	
	# If anything was submitted, validate start and end as ints but emit them as strings
	var start_is_valid_int = start_index.is_valid_int()
	var end_is_valid_int = end_index.is_valid_int()
	
	if ! start_is_valid_int or ! end_is_valid_int:
		if ! start_is_valid_int:
			console_signal_bus.add_error("Invalid start index value given: %s" % start_index)
		if ! end_is_valid_int:
			console_signal_bus.add_error("Invalid end index value given: %s" % end_index)
		return
	
	if end_index.to_int() < start_index.to_int():
		console_signal_bus.add_error("End index must be greater than start index: %s to %s is invalid" % [start_index, end_index])
		return
	
	download_clicked.emit(start_index, end_index)


func _on_visibility_changed() -> void:
	if visible:
		_reset_indices()
		start_input.grab_focus.call_deferred()


func _on_start_input_focus_entered() -> void:
	start_input.select_all()


func _on_end_input_focus_entered() -> void:
	end_input.select_all()
