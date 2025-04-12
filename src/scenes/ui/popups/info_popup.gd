###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name InfoPopup
extends PopupManager.PopupControl

# const BUTTON_SCENE := preload("res://gui/widgets/SquishyButton.tscn")
const DEFAULT_TITLE := "Information"

enum ImagePosition {
    HIDDEN,
    IMAGE_TOP,
    IMAGE_LEFT,
}

@export_tool_button("Redraw") var redraw_button = queue_redraw
@export var title_height: float = 30
@export var title_stylebox: StyleBox
@export var content_stylebox: StyleBox


var title: String = DEFAULT_TITLE:
    set = set_title
var content: String = "":
    set = set_content

var _ref_image: Texture2D = null
var _ref_image_size: Vector2 = Vector2.ZERO
var _ref_image_position: ImagePosition = ImagePosition.HIDDEN

var _buttons: Array[Button] = []
var _button_spacers: Array[Control] = []

var button_autoswap: bool = true
var button_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT:
    set = set_button_alignment

@onready var _title_label: Label = %TitleLabel
@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _top_image_node: TextureRect = %TopImage
@onready var _left_image_node: TextureRect = %LeftImage

@onready var _close_button: Button = %CloseButton
@onready var _button_bar: HBoxContainer = %ButtonBar


func _ready() -> void:
    _update_title()
    _update_content()
    _update_image()
    _update_buttons()

    _close_button.pressed.connect(close_popup)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton && event.is_pressed():
        mark_click_handled()
        accept_event()


func _draw() -> void:
    var popup_origin := Vector2.ZERO

    # Draw content and title.
    var title_size := Vector2(size.x, title_height)
    draw_style_box(content_stylebox, Rect2(popup_origin + Vector2(0, title_height), size - Vector2(0, title_height)))
    draw_style_box(title_stylebox, Rect2(popup_origin, title_size))


#region Lifecycle.
func is_popped() -> bool:
    if not is_node_ready() or not is_inside_tree():
        return false

    return PopupManager.is_popup_shown(self)


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
    if is_node_ready():
        _update_title()
        _update_content()
        _update_buttons()

    PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func move_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT) -> void:
    PopupManager.move_popup_anchored(self, anchor_position, direction)


func close_popup() -> void:
    mark_click_handled()
    PopupManager.hide_popup(self)


func clear() -> void:
    title = DEFAULT_TITLE
    content = ""
    _ref_image = null
    _ref_image_size = Vector2.ZERO
    _ref_image_position = ImagePosition.HIDDEN

    _buttons.clear()
    _button_spacers.clear()

    if is_node_ready():
        _update_image()

        while _button_bar.get_child_count() > 0:
            var child_node := _button_bar.get_child(_button_bar.get_child_count() - 1)
            _button_bar.remove_child(child_node)
            child_node.queue_free()

        _button_bar.visible = false

    custom_minimum_size = Vector2.ZERO
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
    size = Vector2.ZERO
#endregion


#region Content.
func set_title(value: String) -> void:
    title = value
    _update_title()


func _update_title() -> void:
    if not is_node_ready():
        return

    _title_label.text = title


func set_content(value: String) -> void:
    content = value
    _update_content()


func _update_content() -> void:
    if not is_node_ready():
        return

    _content_label.text = content


func add_image(texture: Texture2D, image_size: Vector2, image_position: ImagePosition) -> void:
    _ref_image = texture
    _ref_image_size = image_size
    _ref_image_position = image_position
    _update_image()


func _update_image() -> void:
    if not is_node_ready():
        return

    match _ref_image_position:
        ImagePosition.HIDDEN:
            _top_image_node.custom_minimum_size = Vector2.ZERO
            _top_image_node.visible = false
            _left_image_node.custom_minimum_size = Vector2.ZERO
            _left_image_node.visible = false

        ImagePosition.IMAGE_TOP:
            _top_image_node.texture = _ref_image

            _top_image_node.custom_minimum_size = _ref_image_size
            _top_image_node.visible = true
            _left_image_node.custom_minimum_size = Vector2.ZERO
            _left_image_node.visible = false

        ImagePosition.IMAGE_LEFT:
            _left_image_node.texture = _ref_image

            _top_image_node.custom_minimum_size = Vector2.ZERO
            _top_image_node.visible = false
            _left_image_node.custom_minimum_size = _ref_image_size
            _left_image_node.visible = true
#endregion


#region Buttons.
func add_button(text: String, callback: Callable) -> Button:
    # var button := BUTTON_SCENE.instantiate()
    var button := Button.new()
    button.text = text
    button.pressed.connect(func() -> void:
        mark_click_handled()
        callback.call()
    )

    if button_autoswap && DisplayServer.get_swap_cancel_ok():
        _buttons.push_front(button)
    else:
        _buttons.push_back(button)

    if is_node_ready():
        var spacer: Control = null
        if _buttons.size() > 1:
            spacer = _button_bar.add_spacer(false)
            spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            spacer.visible = (button_alignment == HORIZONTAL_ALIGNMENT_FILL)
            _button_spacers.push_back(spacer)

        _button_bar.add_child(button)

        if button_autoswap && DisplayServer.get_swap_cancel_ok():
            if spacer:
                _button_bar.move_child(spacer, 0)
            _button_bar.move_child(button, 0)

        _button_bar.visible = true

    return button


func _update_buttons() -> void:
    if not is_node_ready():
        return

    var i := 0
    for button in _buttons:
        if not button.get_parent():
            if i > 0:
                var spacer := _button_bar.add_spacer(false)
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                spacer.visible = (button_alignment == HORIZONTAL_ALIGNMENT_FILL)
                _button_spacers.push_back(spacer)

            _button_bar.add_child(button)

        i += 1

    _button_bar.visible = _buttons.size() > 0


func set_button_alignment(value: HorizontalAlignment) -> void:
    button_alignment = value
    _update_button_alignment()


func _update_button_alignment() -> void:
    if not is_node_ready():
        return

    match button_alignment:
        HORIZONTAL_ALIGNMENT_LEFT:
            _button_bar.alignment = BoxContainer.ALIGNMENT_BEGIN

        HORIZONTAL_ALIGNMENT_RIGHT:
            _button_bar.alignment = BoxContainer.ALIGNMENT_END

        HORIZONTAL_ALIGNMENT_CENTER:
            _button_bar.alignment = BoxContainer.ALIGNMENT_CENTER

        HORIZONTAL_ALIGNMENT_FILL:
            _button_bar.alignment = BoxContainer.ALIGNMENT_CENTER

    if button_alignment == HORIZONTAL_ALIGNMENT_FILL:
        for spacer in _button_spacers:
            spacer.visible = true
    else:
        for spacer in _button_spacers:
            spacer.visible = false
#endregion
