class_name SettingsPopup
extends PopupManager.PopupControl

signal settings_valued_changed(path: String, value)

const REVEALER_SCENE = preload("res://scenes/ui/settings/revealer.tscn")

@export var button_group: ButtonGroup

var settings: Dictionary:
    get(): return SettingHelper.settings

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
            match field.get("hint_string", ""):
                "multiline":
                    comp = TextEdit.new()
                    comp.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
                    comp.scroll_fit_content_height = true
                    comp.text = field.get("data")
                    comp.text_changed.connect(func(): settings_valued_changed.emit(comp.get_meta("path"), comp.text))
                "path":
                    comp = HBoxContainer.new()
                    comp.add_theme_constant_override("separation", 8)
                    var label = Label.new()
                    label.size_flags_horizontal = SIZE_EXPAND_FILL
                    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
                    label.text = field.get("data")
                    var button = Button.new()
                    button.text = "select"
                    button.pressed.connect(func(): ProjectManager.load_model(func(path):
                        settings_valued_changed.emit(comp.get_meta("path"), path)
                        label.text = path
                    ))
                    button.theme_type_variation = "SettingButton"
                    comp.add_child(label)
                    comp.add_child(button)
                _:
                    comp = LineEdit.new()
                    comp.text = field.get("data")
                    comp.text_submitted.connect(func(text): settings_valued_changed.emit(comp.get_meta("path"), text))
        TYPE_INT:
            comp = SpinBox.new()
            if field.has("hint_string"):
                var hint_arr = field.get("hint_string").split(",")
                comp.min_value = int(hint_arr[0].strip_edges())
                comp.max_value = int(hint_arr[1].strip_edges())
                comp.step = int(hint_arr[2].strip_edges())
            comp.value = field.get("data")
            comp.value_changed.connect(func(value): settings_valued_changed.emit(comp.get_meta("path"), value))
        TYPE_FLOAT:
            comp = HBoxContainer.new()
            comp.add_theme_constant_override("separation", 8)
            var label = Label.new()
            label.size_flags_horizontal = SIZE_FILL
            label.text = "%s s" % field.get("data")
            var hslider = HSlider.new()
            hslider.size_flags_horizontal = SIZE_EXPAND_FILL
            if field.has("hint_string"):
                var hint_arr = field.get("hint_string").split(",")
                hslider.min_value = float(hint_arr[0].strip_edges())
                hslider.max_value = float(hint_arr[1].strip_edges())
                hslider.step = float(hint_arr[2].strip_edges())
            else:
                hslider.min_value = 0.0
                hslider.max_value = 1.0
                hslider.step = 0.01
            hslider.value = field.get("data")
            hslider.value_changed.connect(func(value):
                settings_valued_changed.emit(comp.get_meta("path"), value)
                label.text = "%s s" % value
            )
            comp.add_child(hslider)
            comp.add_child(label)
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
    SettingHelper.set_setting_value(path, value)
    SettingHelper.save_settings()
