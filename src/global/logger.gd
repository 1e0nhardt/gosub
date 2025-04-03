@tool
extends Node

## 一个简单的日志输出美化类。

enum LogLevel {DEBUG, INFO, WARN, ERROR, FATAL}

const CONFIG := {
    "log_level": LogLevel.DEBUG,
    "format": "[color=#ee9922][{loc_info}][/color] [color=%s]{desc}[/color]{message}",
    # 开头的代码位置信息是否显示方法名
    "loc_info_with_method_name": true,
    "add_colon_after_desc": false,
    "print_raw_string": false,
    # 如果数组元素数量小于等于这个值，则自动紧凑表示
    "compact_array_bound": 5,
    # 如果字典只有一对键值对，则自动紧凑表示
    "compact_dict": false
}

const COLOR_CONFIG := {
    "Array": "#75ad5b",
    "Dictionary": "#ffbf00",
    "Vector": "#3cadd4",
}

const LOG_LEVEL_TO_COLOR: Dictionary = {
    LogLevel.DEBUG: "#dbd7d7",
    LogLevel.INFO: "#3db337",
    LogLevel.WARN: "#c8ce27",
    LogLevel.ERROR: "#c5481b",
    LogLevel.FATAL: "#af2828",
}

func generic_log(message, log_level = LogLevel.INFO, opt = {}):
    if CONFIG["log_level"] > log_level:
        return

    var color_str = LOG_LEVEL_TO_COLOR[log_level]
    var log_msg_format = CONFIG["format"] % color_str

    var loc_info = ""
    var stack_array := []
    if not Engine.is_editor_hint():
        stack_array = get_stack()
        var desired_stack_index = 2 if stack_array.size() >= 3 else 0

        var node_name = opt.get("node_name", "")
        if node_name != "":
            node_name += ":"

        var func_name = ""
        if CONFIG["loc_info_with_method_name"]:
            func_name = stack_array[desired_stack_index]["function"] + ":"

        loc_info = "%s%s:%s%d" % [
            node_name,
            stack_array[desired_stack_index]["source"].split("/")[-1],
            func_name,
            stack_array[desired_stack_index]["line"]]

    var message_string = _format_message(message, opt)

    var desc = opt.get("desc", "")
    if desc == "":
        desc = "%s" % LogLevel.keys()[log_level]
    if CONFIG["add_colon_after_desc"]:
        desc += ":"
    desc += " "

    var formatted_msg = log_msg_format.format(
        {
            "loc_info": loc_info,
            "message": message_string,
            "desc": desc,
        })

    match log_level:
        LogLevel.DEBUG:
            print_rich(formatted_msg)
        LogLevel.INFO:
            print_rich(formatted_msg)
        LogLevel.WARN:
            print_rich(formatted_msg)
            push_warning(message)
        LogLevel.ERROR:
            print_rich(formatted_msg)
            push_error(message)
        LogLevel.FATAL:
            print_rich(formatted_msg)
            push_error(message)
            if is_inside_tree():
                get_tree().quit()
        _:
            print(message)


func _format_message(msg, opt = {}) -> String:
    if msg == null:
        return "null"

    if msg is String:
        if CONFIG["print_raw_string"]:
            msg = msg.c_escape()
            return "\"%s\"" % msg
        else:
            return "%s" % msg

    if msg is StringName:
        if CONFIG["print_raw_string"]:
            msg = msg.c_escape()
            return "&\"%s\"" % msg
        else:
            return "&%s" % msg

    if msg is NodePath:
        if CONFIG["print_raw_string"]:
            msg = msg.c_escape()
            return "^\"%s\"" % msg
        else:
            return "^%s" % msg

    if msg is Array or msg is PackedStringArray:
        if msg.size() == 0:
            return _wrap_color_tag("[]", COLOR_CONFIG["Array"])

        var indent_level = opt.get("indent_level", 0)

        var prettify = opt.get("prettify", false)
        if msg.size() > CONFIG["compact_array_bound"]:
            prettify = true
        if msg[0] is Dictionary:
            prettify = true

        var lf = "\n" if prettify else ""
        var el_indent = "\t".repeat(indent_level + 1) if prettify else ""
        var base_indent = "\t".repeat(indent_level) if prettify else ""

        var fm = _wrap_color_tag("[", COLOR_CONFIG["Array"]) + lf + el_indent + "%s" + lf + base_indent + _wrap_color_tag("]", COLOR_CONFIG["Array"])
        var tmp = ""
        opt = opt.duplicate()
        opt.merge({"indent_level": indent_level + 1}, true)

        for i in len(msg):
            tmp += _format_message(msg[i], opt)
            if i != len(msg) - 1:
                tmp += _wrap_color_tag(",", COLOR_CONFIG["Array"]) + lf + el_indent
        return fm % tmp

    if msg is Dictionary:
        if msg.is_empty():
            return _wrap_color_tag("{}", COLOR_CONFIG["Dictionary"])

        # 与RichTextLabel中不同, print_rich中的开闭tag必须在同一行。
        var indent_level = opt.get("indent_level", 0)
        var base_indent = "" if indent_level == 0 else "\t".repeat(indent_level)
        var tmp = ""
        opt = opt.duplicate() # 避免修改原参数，导致indent_level不正确。
        opt.merge({"indent_level": indent_level + 1}, true)

        var prettify = not opt.get("compact_dict", false)
        if msg.keys().size() == 1:
            prettify = false

        for v in msg.values():
            if v is Dictionary:
                prettify = true
                break

        if not prettify:
            tmp = _wrap_color_tag("{", COLOR_CONFIG["Dictionary"]) + " "
            for k in msg:
                tmp += "%s%s %s%s " % [
                    _format_message(k, opt),
                    _wrap_color_tag(":", COLOR_CONFIG["Dictionary"]),
                    _format_message(msg[k], opt),
                    _wrap_color_tag(",", COLOR_CONFIG["Dictionary"])
                ]
            tmp += _wrap_color_tag("}", COLOR_CONFIG["Dictionary"])
        else:
            tmp = _wrap_color_tag("{", COLOR_CONFIG["Dictionary"]) + "\n"
            for k in msg:
                tmp += base_indent + "\t" + "%s%s %s%s" % [
                    _format_message(k, opt),
                    _wrap_color_tag(":", COLOR_CONFIG["Dictionary"]),
                    _format_message(msg[k], opt),
                    _wrap_color_tag(",", COLOR_CONFIG["Dictionary"])
                ] + "\n"
            tmp += base_indent
            tmp += _wrap_color_tag("}", COLOR_CONFIG["Dictionary"])
        return tmp

    if msg is Vector2 or msg is Vector2i:
        return "%s%s%s %s%s" % [
            _wrap_color_tag("(", COLOR_CONFIG["Vector"]),
            msg.x,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.y,
            _wrap_color_tag(")", COLOR_CONFIG["Vector"]),
        ]

    if msg is Vector3 or msg is Vector3i:
        return "%s%s%s %s%s %s%s" % [
            _wrap_color_tag("(", COLOR_CONFIG["Vector"]),
            msg.x,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.y,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.z,
            _wrap_color_tag(")", COLOR_CONFIG["Vector"]),
        ]

    if msg is Vector4 or msg is Vector4i:
        return "%s%s%s %s%s %s%s %s%s" % [
            _wrap_color_tag("(", COLOR_CONFIG["Vector"]),
            msg.x,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.y,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.z,
            _wrap_color_tag(",", COLOR_CONFIG["Vector"]),
            msg.w,
            _wrap_color_tag(")", COLOR_CONFIG["Vector"]),
        ]

    if msg is Object:
        if msg.has_method("to_pretty"):
            return _format_message(msg.to_pretty(), opt)
        else:
            return msg.to_string()

    return str(msg)


func _wrap_color_tag(s: String, color_str: String) -> String:
    return "[color=%s]%s[/color]" % [color_str, s]


func debug(message, opt = {}):
    call_thread_safe("generic_log", message, LogLevel.DEBUG, opt)


func info(message, opt = {}):
    call_thread_safe("generic_log", message, LogLevel.INFO, opt)


func warn(message, opt = {}):
    call_thread_safe("generic_log", message, LogLevel.WARN, opt)


func error(message, opt = {}):
    call_thread_safe("generic_log", message, LogLevel.ERROR, opt)


func fatal(message, opt = {}):
    call_thread_safe("generic_log", message, LogLevel.FATAL, opt)


func print_raw(message: String):
    print_rich((
        _wrap_color_tag("\"", "#c98870") +
        message.c_escape() +
        _wrap_color_tag("\"", "#c98870")
    ))


func print_func_caller() -> void:
    var stack = get_stack()
    if stack.size() < 3:
        return

    var record = stack[2]
    print_rich(_wrap_color_tag("\"%s\" called by \"%s:%s:%d\"" % [stack[1].get("function"), record.get("source"), record.get("function"), record.get("line")], "#ebf359"))
