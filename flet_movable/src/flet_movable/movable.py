import math
from dataclasses import field
from typing import Optional

import flet as ft
from flet.controls.control_event import ControlEventHandler


@ft.control("movable")
class Movable(ft.LayoutControl):
    """Bounded native dragging; x/y synchronize on release."""

    content: Optional[ft.Control] = None
    x: float = 16
    y: float = 16
    item_width: float = 232
    item_height: float = 72
    edge_padding: float = 8
    haptic: bool = True
    long_press_duration: float = 0.5
    drag_border: Optional[ft.Border] = field(
        default_factory=lambda: ft.Border.all(2, "#65D9C2")
    )
    drag_border_radius: ft.BorderRadiusValue = 22
    on_move_start: Optional[ControlEventHandler["Movable"]] = None
    on_move_cancel: Optional[ControlEventHandler["Movable"]] = None
    on_move_end: Optional[ControlEventHandler["Movable"]] = None

    def before_update(self):
        super().before_update()
        for name in (
            "x",
            "y",
            "item_width",
            "item_height",
            "edge_padding",
            "long_press_duration",
        ):
            value = getattr(self, name)
            if not math.isfinite(value):
                raise ValueError(f"{name} must be finite")
        if self.long_press_duration < 0:
            raise ValueError("long_press_duration must be nonnegative seconds")
        if self.item_width <= 0 or self.item_height <= 0 or self.edge_padding < 0:
            raise ValueError("Dimensions must be positive; padding nonnegative")
