@tool
class_name CustomTabContainer
extends Control

enum TabPosition {
    TOP,
    LEFT,
    RIGHT,
    BOTTOM
}

const TAB_BUTTON_SCENE = preload("res://scenes/ui/custom_tab_button.tscn")
const DEEPSEEK_CHAT_SCENE = preload("res://scenes/ui/deepseek_chat_container.tscn")
const PIPELINE_SCENE = preload("res://scenes/ui/pipeline_container.tscn")
const SUBTITLE_EDIT_SCENE = preload("res://scenes/ui/subtitle_edit_container.tscn")

@export var tab_position: TabPosition = TabPosition.TOP
@export var tab_separation: int = 8
@export var top_margin_left: int = 8
@export var top_margin_right: int = 8
@export var content_margin_left: int = 8
@export var content_margin_right: int = 8
@export var content_margin_top: int = 8
@export var content_margin_bottom: int = 8
@export var tab_font_size: int = 20
@export var tab_height: int = 36
@export var initial_tab_index: int = 0


var current_tab: int = 0:
    set(value):
        current_tab = value
        if not is_node_ready():
            return

        if content_margin.get_child(0):
            content_margin.remove_child(content_margin.get_child(0))

        tab_scene_instances[current_tab] = get_tab_scene_instance(current_tab)
        content_margin.add_child(tab_scene_instances[current_tab])

        for i in tab_buttons.size():
            tab_buttons[i].selected = (i == value)

var tab_button_group: ButtonGroup = ButtonGroup.new()
var tab_labels := ["Pipeline", "Subtitle", "Deepseek"]
var tab_buttons := []
var tab_scene_instances := [null, null, null]
var layout_box: BoxContainer
var tab_bar: BoxContainer
var tab_panel: PanelContainer
var top_margin: MarginContainer
var content_margin: MarginContainer

var tab_bar_stylebox: StyleBox
var tab_panel_stylebox: StyleBox


func _init() -> void:
    layout_box = VBoxContainer.new()
    top_margin = MarginContainer.new()


func _ready() -> void:
    tab_bar_stylebox = get_theme_stylebox("tab_bar", "GosubTabContainer")
    tab_panel_stylebox = get_theme_stylebox("tab_panel", "GosubTabContainer")

    layout_box.add_theme_constant_override("separation", 0)
    layout_box.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(layout_box)

    top_margin.add_theme_constant_override("margin_left", top_margin_left)
    top_margin.add_theme_constant_override("margin_right", top_margin_right)
    tab_bar = HBoxContainer.new()
    tab_bar.add_theme_constant_override("separation", tab_separation)
    top_margin.add_child(tab_bar)
    layout_box.add_child(top_margin)
    for i in tab_labels.size():
        var tab_button = TAB_BUTTON_SCENE.instantiate()
        tab_button.pressed.connect(func(): current_tab = i)
        tab_button.custom_minimum_size.y = tab_height
        tab_button.text = tab_labels[i]
        tab_button.add_theme_font_size_override("font_size", tab_font_size)
        tab_button.button_group = tab_button_group
        tab_bar.add_child(tab_button)
        tab_buttons.append(tab_button)

    var tab_scene = get_tab_scene_instance(initial_tab_index)
    tab_scene_instances[current_tab] = tab_scene
    content_margin = MarginContainer.new()
    content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_margin.add_theme_constant_override("margin_left", content_margin_left)
    content_margin.add_theme_constant_override("margin_right", content_margin_right)
    content_margin.add_theme_constant_override("margin_top", content_margin_top)
    content_margin.add_theme_constant_override("margin_bottom", content_margin_bottom)
    content_margin.add_child(tab_scene)
    layout_box.add_child(content_margin)

    current_tab = initial_tab_index
    tab_buttons[current_tab].selected = true

    queue_redraw.call_deferred()


func _draw() -> void:
    if tab_bar_stylebox:
        draw_style_box(tab_bar_stylebox, Rect2(Vector2.ZERO, top_margin.size))

    if content_margin:
        draw_style_box(tab_panel_stylebox, Rect2(Vector2(0, top_margin.size.y), content_margin.size))


func _get_minimum_size() -> Vector2:
    return layout_box.get_combined_minimum_size()


func get_tab_scene_instance(index: int) -> Control:
    if tab_scene_instances[index]:
        return tab_scene_instances[index]

    match index:
        0:
            return PIPELINE_SCENE.instantiate()
        1:
            return SUBTITLE_EDIT_SCENE.instantiate()
        2:
            return DEEPSEEK_CHAT_SCENE.instantiate()
        _:
            Logger.warn("Invalid tab index")
            return null
