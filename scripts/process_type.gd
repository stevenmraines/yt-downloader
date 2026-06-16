class_name Process extends Node

signal progress_timer_timeout(process : Process)

# TODO Maybe add a setter to kill/skip all child/sibling processes when this is killed/skipped?
var status := ProcessState.QUEUED
var exit_code := 0
var pid := -1
var process_name := ""
var killable := true
var playlist := {}
var data := {}
var progress_timer := Timer.new()
var parent_process : Process
var child_processes : Array[Process]
# TODO Figure out how to handle skipping dependent child/sibling processes
var dependent_processes : Array[Process]

const PROGRESS_CHECK_DURATION := 0.5

enum ProcessState { QUEUED, IN_PROGRESS, COMPLETE, FAILED, KILLED, SKIPPED }


func _ready() -> void:
	progress_timer.wait_time = PROGRESS_CHECK_DURATION
	progress_timer.autostart = false
	progress_timer.one_shot = false
	add_child(progress_timer)
	progress_timer.timeout.connect(_on_progress_timer_timeout)


func _on_progress_timer_timeout() -> void:
	progress_timer_timeout.emit(self)
