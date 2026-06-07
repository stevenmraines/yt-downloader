extends Control

@export var title := "":
	set(value):
		title = value
		if title_label:
			title_label.text = title

@onready var title_label := $TitleLabel
