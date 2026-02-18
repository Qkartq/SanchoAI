import flet as ft
from flet import Container, Column, Text, Row, ProgressBar


class MessageBubble(Container):
    def __init__(self, role: str, content: str, **kwargs):
        is_user = role == "user"
        
        bubble_color = ft.Colors.PRIMARY_CONTAINER if is_user else ft.Colors.SURFACE_CONTAINER_HIGH
        text_color = ft.Colors.ON_PRIMARY_CONTAINER if is_user else ft.Colors.ON_SURFACE_VARIANT
        alignment = ft.Alignment(1, 0) if is_user else ft.Alignment(-1, 0)
        margin = ft.margin.only(left=50, right=0) if is_user else ft.margin.only(left=0, right=50)
        
        super().__init__(
            content=ft.Column([
                ft.Text(
                    content,
                    color=text_color,
                    size=14,
                    selectable=True,
                )
            ], tight=True, spacing=5),
            alignment=alignment,
            margin=margin,
            padding=12,
            border_radius=16,
            bgcolor=bubble_color,
            **kwargs
        )


class LoadingIndicator(Container):
    def __init__(self, text: str = "Думаю..."):
        super().__init__(
            content=Column([
                Row([
                    ft.ProgressRing(width=16, height=16, stroke_width=2),
                    Text(text, size=14, color=ft.Colors.ON_SURFACE_VARIANT),
                ], spacing=8),
                AnimatedDots(),
            ], tight=True, spacing=5),
            alignment=ft.Alignment(-1, 0),
            margin=ft.margin.only(left=0, right=50),
            padding=12,
            border_radius=16,
            bgcolor=ft.Colors.SURFACE_CONTAINER_HIGH,
            width=200,
        )


class AnimatedDots(Row):
    def __init__(self):
        super().__init__(spacing=2)
        self.dot1 = ft.Text("...", size=14, color=ft.Colors.ON_SURFACE_VARIANT)
        self.dot2 = ft.Text("...", size=14, color=ft.Colors.ON_SURFACE_VARIANT)
        self.dot3 = ft.Text("...", size=14, color=ft.Colors.ON_SURFACE_VARIANT)
        self.controls = [self.dot1, self.dot2, self.dot3]
