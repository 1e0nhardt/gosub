@tool
class_name StyleBoxLineEx
extends StyleBox

@export var color: Color = Color.WHITE
@export var thickness: int = 1
@export var grow_begin: int = 0
@export var grow_end: int = 0
@export var offset: int = 0
@export var vertical: bool = false


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
    # calculate position
    var line_start := rect.position + (Vector2(rect.size.x - self.offset, -self.grow_begin) if self.vertical else Vector2(-self.grow_begin, rect.size.y - self.offset))
    var line_end := rect.end + (Vector2(-self.offset, self.grow_end) if self.vertical else Vector2(self.grow_end, -self.offset))

    # add offset that prevents the line from being drawn outside of the rect
    line_start = line_start - (Vector2(self.thickness / 2.0, 0) if self.vertical else Vector2(0, self.thickness / 2.0))
    line_end = line_end - (Vector2(self.thickness / 2.0, 0) if self.vertical else Vector2(0, self.thickness / 2.0))

    RenderingServer.canvas_item_add_line(to_canvas_item, line_start, line_end, self.color, self.thickness, false)
