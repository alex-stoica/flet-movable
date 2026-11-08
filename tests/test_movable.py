import json
import unittest
import weakref
from unittest.mock import AsyncMock, MagicMock

import flet as ft
from flet_movable import Movable


class MovableTests(unittest.TestCase):
    def test_invalid_geometry_and_duration(self):
        for kwargs in (
            {"long_press_duration": -1},
            {"x": float("nan")},
            {"y": float("inf")},
            {"item_width": 0},
            {"item_height": -1},
            {"edge_padding": -1},
        ):
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                Movable(**kwargs).before_update()

    def test_optional_outline_and_independent_defaults(self):
        Movable(drag_border=None, long_press_duration=0).before_update()
        first, second = Movable(), Movable()
        self.assertIsNot(first.drag_border, second.drag_border)


class EventTests(unittest.IsolatedAsyncioTestCase):
    async def test_wire_payloads_reach_python(self):
        received = []
        session = MagicMock()
        session.after_event = AsyncMock()
        page = ft.Page(session)

        def handler(event):
            received.append((event.name, json.loads(event.data)))

        control = Movable(
            on_move_start=handler, on_move_end=handler, on_move_cancel=handler
        )
        control._parent = weakref.ref(page)
        for name in ("move_start", "move_end", "move_cancel"):
            data = {"x": 20.0, "y": 30.0}
            if name == "move_cancel":
                data["reason"] = "pointer_cancelled"
            await control._trigger_event(name, json.dumps(data))
            self.assertEqual(received[-1], (name, data))
        self.assertEqual(len(received), 3)
