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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		visible = false


func _on_start_input_text_changed(new_text: String) -> void:
	start_index = new_text


func _on_end_input_text_changed(new_text: String) -> void:
	end_index = new_text


func _on_button_button_up() -> void:
	download_clicked.emit(start_index, end_index)


func _on_text_submitted(_new_text : String) -> void:
	download_clicked.emit(start_index, end_index)
