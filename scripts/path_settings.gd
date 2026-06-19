extends HBoxContainer

@onready var name_label := %NameLabel
@onready var path_input := %PathInput
@onready var path_file_dialog := %PathFileDialog

var path : Dictionary:
	set(value):
		path = value
		name_label.text = path.name + " Path"
		path_input.text = path.path


func _on_browse_button_button_up():
	path_file_dialog.visible = true


func _on_path_file_dialog_file_selected(new_path):
	path.path = new_path
	path_input.text = new_path
