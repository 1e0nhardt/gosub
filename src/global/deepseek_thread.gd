extends Node

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false
var request_handled := true


# The thread will start here.
func _ready():
    mutex = Mutex.new()
    semaphore = Semaphore.new()
    exit_thread = false

    thread = Thread.new()
    thread.start(_thread_function)


func _physics_process(_delta: float) -> void:
    if get_handled_flag():
        semaphore.post()


func _thread_function():
    while true:
        semaphore.wait() # Wait until posted.

        mutex.lock()
        var should_exit = exit_thread # Protect with Mutex.
        mutex.unlock()

        if should_exit:
            break

        mutex.lock()
        request_handled = false
        mutex.unlock()

        DeepSeekApi.poll()

        mutex.lock()
        request_handled = true
        mutex.unlock()


func get_handled_flag() -> bool:
    mutex.lock()
    var value = request_handled
    mutex.unlock()
    return value


# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
    # Set exit condition to true.
    mutex.lock()
    exit_thread = true # Protect with Mutex.
    mutex.unlock()

    # Unblock by posting.
    semaphore.post()

    # Wait until it exits.
    thread.wait_to_finish()
