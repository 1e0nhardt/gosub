class_name SettingHelper
extends Object

const SETTINGS_PATH: String = "user://settings.json"

static var settings := {}


static func load_settings() -> void:
    if FileAccess.file_exists(SETTINGS_PATH):
        settings = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
    else:
        settings = Constant.DEFAULT_SETTINGS


static func save_settings() -> void:
    var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(settings))
    file.close()


static func get_setting_value(path: String) -> Variant:
    var dict = settings
    for p in path.split("/", false):
        dict = dict.get(p, {})
    return dict.get("data", null)


static func set_setting_value(path: String, value: Variant) -> void:
    var value_dict = settings
    for p in path.split("/", false):
        value_dict = value_dict.get(p)
    value_dict["data"] = value