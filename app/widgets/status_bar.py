import flet as ft
from flet import Container, Row, Text, ProgressRing, Column


class ModelStatus:
    LOADING = "loading"
    READY = "ready"
    IDLE = "idle"
    GENERATING = "generating"


class StatusBar(Container):
    def __init__(self, page=None, lang: str = "ru", **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self.lang = lang
        self.current_status = ModelStatus.IDLE
        
        self.status_indicator = Container(
            width=10,
            height=10,
            border_radius=5,
            bgcolor=ft.Colors.BLUE_GREY_400,
        )
        
        self.status_text = Text(
            "⏳ Ожидание...",
            size=13,
            color=ft.Colors.ON_SURFACE_VARIANT,
        )
        
        self.progress_ring = ProgressRing(width=14, height=14, stroke_width=2, visible=False)
        
        self.content = Row([
            self.status_indicator,
            self.progress_ring,
            self.status_text,
        ], spacing=8, vertical_alignment=ft.CrossAxisAlignment.CENTER)
        
        self.padding = ft.padding.symmetric(horizontal=15, vertical=8)
        self.bgcolor = ft.Colors.SURFACE_CONTAINER_LOWEST
        self.height = 36
        
    def _get_colors(self):
        if self._page and self._page.theme:
            return {
                "idle": ft.Colors.BLUE_GREY_400,
                "loading": ft.Colors.DEEP_ORANGE_400,
                "ready": ft.Colors.GREEN_400,
                "generating": ft.Colors.BLUE_400,
            }
        return {
            "idle": ft.Colors.BLUE_GREY_400,
            "loading": ft.Colors.DEEP_ORANGE_400,
            "ready": ft.Colors.GREEN_400,
            "generating": ft.Colors.BLUE_400,
        }
        
    def set_status(self, status: str):
        self.current_status = status
        
        colors = self._get_colors()
        
        status_config = {
            ModelStatus.IDLE: {
                "color": colors["idle"],
                "icon": "⏳",
                "text": "Ожидание..." if self.lang == "ru" else "Idle...",
                "progress": False,
            },
            ModelStatus.LOADING: {
                "color": colors["loading"],
                "icon": "📥",
                "text": "Загрузка модели..." if self.lang == "ru" else "Loading model...",
                "progress": True,
            },
            ModelStatus.READY: {
                "color": colors["ready"],
                "icon": "✅",
                "text": "Модель готова" if self.lang == "ru" else "Model ready",
                "progress": False,
            },
            ModelStatus.GENERATING: {
                "color": colors["generating"],
                "icon": "🤖",
                "text": "Генерация ответа..." if self.lang == "ru" else "Generating response...",
                "progress": True,
            },
        }
        
        config = status_config.get(status, status_config[ModelStatus.IDLE])
        
        self.status_indicator.bgcolor = config["color"]
        self.status_text.value = f"{config['icon']} {config['text']}"
        self.progress_ring.visible = config["progress"]
        
        self.update()
    
    def update_language(self, lang: str):
        self.lang = lang
        self.set_status(self.current_status)
