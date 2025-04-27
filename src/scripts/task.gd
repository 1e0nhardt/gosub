class_name Task
extends RefCounted

var id: int
var task: Callable
var callback: Callable


func _init(a_task: Callable, a_callback: Callable = Callable()):
    task = a_task
    callback = (func(): pass ) if a_callback.is_null() else a_callback


func run() -> void:
    id = WorkerThreadPool.add_task(task)


func call_callback() -> void:
    callback.call()


func check_callables() -> bool:
    if not check_callables_validity():
        return false

    if not check_callables_arguments():
        return false

    return true


func check_callables_validity() -> bool:
    if not task.is_valid():
        Logger.error("task function is not valid!")
        return false

    if not callback.is_valid():
        Logger.error("callback function is not valid!")
        return false

    return true


func check_callables_arguments() -> bool:
    if task.get_argument_count() != 0:
        Logger.error("StatedTask: task function must take no argument!")
        return false

    if callback.get_argument_count() != 0:
        Logger.error("Task: callback function must take no argument!")
        return false

    return true