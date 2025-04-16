class_name SettingsPopup
extends PopupManager.PopupControl

signal settings_valued_changed(path: String, value)

const REVEALER_SCENE = preload("res://scenes/ui/settings/revealer.tscn")

@export var button_group: ButtonGroup

var settings: Dictionary:
    get(): return ProjectManager.settings

@onready var close_button: Button = %CloseButton
@onready var category_vbox: VBoxContainer = %CategoryVBox
@onready var items_vbox: VBoxContainer = %ItemsVBox


func _ready() -> void:
    close_button.pressed.connect(close_popup)
    items_vbox.sort_children.connect(_on_items_vbox_sort)
    settings_valued_changed.connect(_on_settings_valued_changed)
    var first_category = settings.keys()[0]
    for k in settings.keys():
        add_category_button(k)
    _on_change_category(first_category)


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    ProjectManager.show_blocker()
    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)
    ProjectManager.hide_blocker()


func add_category_button(category: String) -> void:
    var button = Button.new()
    button.theme_type_variation = "SettingButton"
    button.toggle_mode = true
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.text = category
    button.button_group = button_group
    button.pressed.connect(_on_change_category.bind(category))
    category_vbox.add_child(button)


func add_revealer(title: String, data: Dictionary, parent: Control, expand: bool = false) -> void:
    var revealer := REVEALER_SCENE.instantiate() as Revealer
    parent.add_child(revealer)
    revealer.set_title(title)
    revealer.is_expanded = expand
    revealer._toggle_content(expand, true)
    var parent_path = parent.get_meta("path", "")
    revealer.set_meta("path", parent_path + "/" + title)

    for key in data.keys():
        if data.get(key).has("data"):
            var hbox := HBoxContainer.new()
            hbox.add_theme_constant_override("separation", 12)
            var label = Label.new()
            label.text = key
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            label.size_flags_horizontal = SIZE_EXPAND_FILL
            label.size_flags_stretch_ratio = 0.6
            var value_comp = prepare_value_component(data.get(key))
            value_comp.set_meta("path", revealer.get_meta("path") + "/" + key)
            hbox.add_child(label)
            hbox.add_child(value_comp)
            revealer.add_child(hbox)
        else:
            add_revealer(key, data.get(key), revealer)


func clear_contents() -> void:
    for child in items_vbox.get_children():
        child.queue_free()


func prepare_value_component(field: Dictionary) -> Control:
    var comp
    match int(field.get("type")):
        TYPE_BOOL:
            comp = CheckBox.new()
            comp.theme_type_variation = "SettingCheckbox"
            comp.button_pressed = field.get("data")
            comp.pressed.connect(func(): settings_valued_changed.emit(comp.get_meta("path"), comp.button_pressed))
        TYPE_STRING:
            if field.get("hint_string", "") == "multiline":
                comp = TextEdit.new()
                comp.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
                comp.scroll_fit_content_height = true
                comp.text_changed.connect(func(): settings_valued_changed.emit(comp.get_meta("path"), comp.text))
            else:
                comp = LineEdit.new()
                comp.text_submitted.connect(func(text): settings_valued_changed.emit(comp.get_meta("path"), text))
            comp.text = field.get("data")
        TYPE_INT:
            comp = SpinBox.new()
            comp.value = field.get("data")
            comp.value_changed.connect(func(value): settings_valued_changed.emit(comp.get_meta("path"), value))
        TYPE_FLOAT:
            comp = HSlider.new()
            comp.min_value = 0.0
            comp.max_value = 1.0
            comp.step = 0.01
            comp.value = field.get("data")
            comp.value_changed.connect(func(value): settings_valued_changed.emit(comp.get_meta("path"), value))
        TYPE_COLOR:
            comp = ColorPickerButton.new()
            comp.color = Color(field.get("data"))
            comp.color_changed.connect(func(color): settings_valued_changed.emit(comp.get_meta("path"), comp.color.to_html()))
        _:
            comp = Label.new()
            comp.text = "There is no type for this value."

    comp.size_flags_vertical = SIZE_FILL
    comp.size_flags_horizontal = SIZE_EXPAND_FILL
    return comp


func _on_change_category(category: String) -> void:
    # Logger.info(settings.get(category))
    clear_contents()
    items_vbox.set_meta("path", "/" + category)
    for key in settings.get(category).keys():
        add_revealer(key, settings.get(category).get(key), items_vbox, true)


func _on_items_vbox_sort() -> void:
    for child in items_vbox.get_children():
        child.queue_redraw()


func _on_settings_valued_changed(path: String, value) -> void:
    Logger.info("%s: %s" % [path, value])
    ProjectManager.set_setting_value(path, value)
    ProjectManager.save_settings()
