class_name Profiler
extends Object

static var _data := {}


static func start(name) -> void:
    _data[name] = Time.get_ticks_usec()


static func stop(name) -> void:
    var time = Time.get_ticks_usec() - _data[name]
    Logger.info("%s: %d us" % [name, time])


static func clear() -> void:
    _data = {}


static func print() -> void:
    Logger.info("Profiler _data:")
    Logger.info(_data)
