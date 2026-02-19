import flet as ft
from flet import Container, Row, Text, ProgressRing, Column


class ModelStatus:
    LOADING = "loading"
    READY = "ready"
    IDLE = "idle"
    GENERATING = "generating"
    ERROR = "error"


class StatusBar(Container):
    def __init__(self, page=None, lang: str = "ru", **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self.lang = lang
        self.current_status = ModelStatus.IDLE
        
        self._indicator = Container(
            width=12,
            height=12,
            border_radius=6,
            bgcolor=ft.Colors.BLUE_GREY_400,
        )
        
        self._text = Text(
            "⏳ Ожидание...",
            size=13,
            color=ft.Colors.ON_SURFACE_VARIANT,
        )
        
        self._progress = ProgressRing(
            width=14, 
            height=14, 
            stroke_width=2, 
            visible=False,
        )
        
        self.content = Row(
            [self._indicator, self._progress, self._text],
            spacing=8, 
            vertical_alignment=ft.CrossAxisAlignment.CENTER
        )
        
        self.padding = ft.padding.symmetric(horizontal=15, vertical=8)
        self.bgcolor = ft.Colors.SURFACE_CONTAINER_LOWEST
        self.height = 36
    
    def set_status(self, status: str):
        self.current_status = status
        
        status_config = {
            ModelStatus.IDLE: {
                "color": ft.Colors.BLUE_GREY_400,
                "icon": "⏳",
                "text": "Ожидание..." if self.lang == "ru" else "Idle...",
                "progress": False,
            },
            ModelStatus.LOADING: {
                "color": ft.Colors.DEEP_ORANGE_400,
                "icon": "📥",
                "text": "Загрузка модели..." if self.lang == "ru" else "Loading model...",
                "progress": True,
            },
            ModelStatus.READY: {
                "color": ft.Colors.GREEN_400,
                "icon": "✅",
                "text": "Модель готова" if self.lang == "ru" else "Model ready",
                "progress": False,
            },
            ModelStatus.GENERATING: {
                "color": ft.Colors.BLUE_400,
                "icon": "🤖",
                "text": "Генерация ответа..." if self.lang == "ru" else "Generating response...",
                "progress": True,
            },
            ModelStatus.ERROR: {
                "color": ft.Colors.RED_400,
                "icon": "❌",
                "text": "Ошибка загрузки" if self.lang == "ru" else "Load error",
                "progress": False,
            },
        }
        
        config = status_config.get(status, status_config[ModelStatus.IDLE])
        
        self._indicator.bgcolor = config["color"]
        self._text.value = f"{config['icon']} {config['text']}"
        self._progress.visible = config["progress"]
        
        self.update()
    
    def update_language(self, lang: str):
        self.lang = lang
        self.set_status(self.current_status)
