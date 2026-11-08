import asyncio
import json
import flet as ft
from flet_movable import Movable


async def main(page: ft.Page):
    page.title = "Movable Demo"
    page.theme_mode = ft.ThemeMode.DARK
    page.bgcolor = "#0D1420"
    page.padding = 16
    clock = ft.Text("00:00", size=28, weight=ft.FontWeight.W_600, color="#F1F5F9")
    status = ft.Text("0 drops · native movement", size=12, color="#91A1B8")
    drops = 0
    running = True

    def dropped(e):
        nonlocal drops
        drops += 1
        data = json.loads(e.data) if isinstance(e.data, str) else e.data
        status.value = f"{drops} drops · x={data['x']:.0f}, y={data['y']:.0f}"
        status.update()

    def started(e):
        status.value = "START - native movement"
        status.update()

    def cancelled(e):
        data = json.loads(e.data) if isinstance(e.data, str) else e.data
        status.value = f"CANCEL - {data['reason']}"
        status.update()

    def toggle(e):
        nonlocal running
        running = not running
        e.control.icon = ft.Icons.PAUSE if running else ft.Icons.PLAY_ARROW
        e.control.update()

    timer = Movable(
        x=24,
        y=55,
        item_width=260,
        item_height=88,
        on_move_end=dropped,
        on_move_start=started,
        on_move_cancel=cancelled,
        content=ft.Container(
            bgcolor="#24344D",
            border_radius=22,
            padding=16,
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.DRAG_INDICATOR, color="#91A1B8"),
                    ft.Column(
                        [
                            clock,
                            ft.Text("0.5 s / green outline", size=11, color="#91A1B8"),
                        ],
                        spacing=0,
                        tight=True,
                        expand=True,
                    ),
                    ft.IconButton(
                        ft.Icons.PAUSE, on_click=toggle, icon_color="#65D9C2"
                    ),
                ]
            ),
        ),
    )
    note = Movable(
        long_press_duration=1.2,
        drag_border=None,
        x=65,
        y=215,
        item_width=220,
        item_height=100,
        on_move_end=dropped,
        on_move_start=started,
        on_move_cancel=cancelled,
        content=ft.Container(
            bgcolor="#534526",
            border_radius=22,
            padding=18,
            content=ft.Column(
                [
                    ft.Text("Move this card too", size=17, weight=ft.FontWeight.W_600),
                    ft.Text("1.2 s / no outline", size=12),
                ],
                spacing=8,
            ),
        ),
    )
    page.add(
        ft.Column(
            [
                ft.Text("Movable", size=32, weight=ft.FontWeight.BOLD),
                ft.Text(
                    "Hold until it vibrates, then drag without lifting your finger.",
                    size=14,
                    color="#91A1B8",
                ),
                ft.Container(
                    expand=True,
                    bgcolor="#131E2E",
                    border_radius=24,
                    content=ft.Stack([timer, note], fit=ft.StackFit.EXPAND),
                ),
                status,
            ],
            expand=True,
            spacing=16,
        )
    )
    seconds = 0
    while True:
        await asyncio.sleep(1)
        if running:
            seconds += 1
            clock.value = f"{seconds // 60:02d}:{seconds % 60:02d}"
            clock.update()


ft.run(main)
