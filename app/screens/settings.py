import flet as ft
from flet import Column, Container, Text, Row, Button, OutlinedButton, TextField, Divider
import json
import os


class SettingsScreen(Column):
    def __init__(self, pg, services, lang: str = "en", app=None, **kwargs):
        super().__init__(**kwargs)
        self._page = pg
        self.services = services
        self.lang = lang
        self.app = app
        self.settings = None
        
        self.system_prompt_field = TextField(
            label="AI Personality (System Prompt)",
            hint_text="Define how the AI assistant behaves...",
            multiline=True,
            min_lines=3,
            max_lines=6,
            width=300,
        )
        
        self.theme_buttons = Row([
            Button(content=Text("☀️ Light"), on_click=lambda _: self.change_theme("light")),
            Button(content=Text("🌙 Dark"), on_click=lambda _: self.change_theme("dark")),
            Button(content=Text("📱 System"), on_click=lambda _: self.change_theme("system")),
        ], spacing=10, alignment=ft.MainAxisAlignment.CENTER)
        
        self.current_theme = Text("Theme: System", size=14)
        
        self.save_button = Button(
            content=Text("Save"),
            on_click=self.save_settings,
            width=120,
        )
        
        self.export_button = Button(
            content=Text("Export Chat (JSON)"),
            on_click=self.export_chat,
            width=200,
        )
        
        self.clear_button = OutlinedButton(
            content=Text("Clear History"),
            on_click=self.show_clear_dialog,
            width=200,
        )
        
        self.controls = [
            Text("Settings", size=24, weight=ft.FontWeight.BOLD),
            Container(height=10),
            Text("Appearance", size=18, weight=ft.FontWeight.BOLD),
            Container(height=5),
            self.theme_buttons,
            self.current_theme,
            Container(height=30),
            Divider(),
            Container(height=10),
            Text("AI Personality", size=18, weight=ft.FontWeight.BOLD),
            Container(height=5),
            self.system_prompt_field,
            Container(height=10),
            self.save_button,
            Container(height=30),
            Divider(),
            Container(height=10),
            Text("Data", size=18, weight=ft.FontWeight.BOLD),
            Container(height=10),
            self.export_button,
            Container(height=10),
            self.clear_button,
            Container(height=30),
            Divider(),
            Container(height=10),
            Text("About", size=18, weight=ft.FontWeight.BOLD),
            Container(height=5),
            Text("AI Companion v1.0", size=14),
            Text("Local AI-powered assistant", size=12, color=ft.Colors.ON_SURFACE),
        ]
        
        self.spacing = 10
        self.padding = 20
        self.scroll = ft.ScrollMode.AUTO
        self.horizontal_alignment = ft.CrossAxisAlignment.CENTER

    def get_text(self, key: str) -> str:
        from ..i18n import get_translation
        return get_translation(self.lang, key)

    async def load_settings(self):
        self.settings = await self.services.db.get_settings()
        if self.settings:
            self.system_prompt_field.value = self.settings.system_prompt
            self.current_theme.value = f"Theme: {self.settings.theme.capitalize()}"
        self._page.update()

    def change_theme(self, theme):
        if self.app:
            self.app.setup_theme(theme)
        self.current_theme.value = f"Theme: {theme.capitalize()}"
        self._page.update()

    async def save_settings(self, e=None):
        if self.settings:
            self.settings.system_prompt = self.system_prompt_field.value
            await self.services.db.update_settings(self.settings)
            self.services.ai.set_system_prompt(self.settings.system_prompt)
        
        print("Settings saved!")

    async def export_chat(self, e=None):
        try:
            conversation_id = 1
            data = await self.services.db.export_conversation_json(conversation_id)
            
            from ..utils.helpers import get_app_dir, save_json
            export_path = os.path.join(get_app_dir(), "chat_export.json")
            save_json(data, export_path)
            
            print(f"Exported to {export_path}")
        except Exception as ex:
            print(f"Export error: {ex}")

    async def show_clear_dialog(self, e=None):
        await self.services.db.clear_all_messages()
        if self.app and hasattr(self.app, 'chat_screen'):
            self.app.chat_screen.messages = []
            self.app.chat_screen.messages_list.controls.clear()
            self.app.chat_screen._page.update()
        print("History cleared")
        self._page.update()
