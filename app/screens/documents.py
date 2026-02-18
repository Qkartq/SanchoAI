import flet as ft
from flet import Column, Text


class DocumentsScreen(Column):
    def __init__(self, pg, services, lang: str = "en", **kwargs):
        super().__init__(**kwargs)
        self._page = pg
        self.services = services
        self.lang = lang
        
        self.controls = [
            Text("Document analysis available in chat", size=16),
            Text("Attach documents using the chat input", size=14, color=ft.Colors.ON_SURFACE),
        ]
        
        self.expand = True
