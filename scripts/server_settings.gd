extends FoldableContainer

signal server_deleted(server : Dictionary)

@onready var name_input := %NameInput
@onready var ip_input := %IPInput
@onready var user_input := %UserInput
@onready var ssh_key_path_input := %SSHKeyPathInput
@onready var ssh_key_path_file_dialog := %SSHKeyPathFileDialog
@onready var is_default_input := %IsDefaultInput
@onready var delete_button := %DeleteButton

var server : Dictionary:
	set(value):
		server = value
		title = server.name
		name_input.text = server.name
		ip_input.text = server.ip
		user_input.text = server.user
		ssh_key_path_input.text = server.ssh_key_path
		is_default_input.button_pressed = server.is_default
		delete_button.text = "Delete Server %s" % server.name


func _on_name_input_text_changed(new_text: String) -> void:
	server.name = new_text
	title = new_text
	delete_button.text = "Delete Server %s" % new_text


func _on_delete_button_button_up() -> void:
	server_deleted.emit(server)


func _on_ip_input_text_changed(new_text):
	server.ip = new_text


func _on_user_input_text_changed(new_text):
	server.user = new_text


func _on_ssh_key_path_input_text_changed(new_text):
	# TODO Also handle when browse button is used
	server.ssh_key_path = new_text


func _on_is_default_input_toggled(toggled_on):
	server.is_default = toggled_on
