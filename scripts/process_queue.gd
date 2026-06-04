class_name ProcessQueue extends Node

enum ProcessState { QUEUED, IN_PROGRESS, COMPLETE, KILLED }

var processes := {}


# TODO Figure out if all this is needed, might need to use OS.is_process_running(pid)
func queue_process(pid : int) -> void:
	processes[pid] = ProcessState.QUEUED


func mark_process_as_in_progress(pid : int) -> void:
	processes[pid] = ProcessState.IN_PROGRESS


func mark_process_as_complete(pid : int) -> void:
	processes[pid] = ProcessState.COMPLETE


func kill_process(pid : int) -> void:
	OS.kill(pid)
	processes[pid] = ProcessState.KILLED
