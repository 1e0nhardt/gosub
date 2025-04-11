class_name Clip
extends RefCounted

# var _id: int
## 起始时间(微秒)
var start: int = 0
var end: int = 0

# 有一点精度损失
var start_time: float:
    get(): return start / 1000.0
var end_time: float:
    get(): return end / 1000.0

## 0: 时间在clip内。 1: 时间在clip后。 2: 时间在clip前。
func compare(time: float) -> int:
    time = int(time * 1000)
    if time > end:
        return 1
    elif time < start:
        return -1
    else:
        return 0


func get_duration() -> int:
    return end - start


func get_start_timestamp(format := "ass") -> String:
    return Util.time_ms2str(start, format)


func get_end_timestamp(format := "ass") -> String:
    return Util.time_ms2str(end, format)


func set_start_timestamp(time: String, format := "ass") -> void:
    start = Util.time_str2ms(time, format)


func set_end_timestamp(time: String, format := "ass") -> void:
    end = Util.time_str2ms(time, format)