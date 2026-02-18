import flet as ft
from flet import Column, Container, Text, Row, FilledButton, OutlinedButton, TextField, Card, VerticalDivider, AppBar, IconButton
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
        
        self.app_bar = AppBar(
            title=Text("Настройки", size=20, weight=ft.FontWeight.W_500),
            leading=IconButton(
                icon=ft.Icon(ft.Icons.ARROW_BACK, size=24),
                on_click=self.go_back,
                tooltip="Назад",
            ),
            leading_width=48,
            elevation=1,
            bgcolor=ft.Colors.SURFACE,
        )
        
        self.system_prompt_field = TextField(
            label="Личность ИИ",
            hint_text="Опишите, как должен вести себя ИИ помощник...",
            multiline=True,
            min_lines=3,
            max_lines=6,
            filled=True,
            border_color=ft.Colors.PRIMARY,
        )
        
        self.theme_buttons = Row([
            FilledButton(
                content=Text("Светлая"),
                on_click=lambda _: self.change_theme("light"),
            ),
            FilledButton(
                content=Text("Тёмная"),
                on_click=lambda _: self.change_theme("dark"),
            ),
            FilledButton(
                content=Text("Системная"),
                on_click=lambda _: self.change_theme("system"),
            ),
        ], spacing=10, alignment=ft.MainAxisAlignment.CENTER)
        
        self.current_theme = Text("Тема: Системная", size=14, color=ft.Colors.ON_SURFACE_VARIANT)
        
        self.save_button = FilledButton(
            content=Text("Сохранить", weight=ft.FontWeight.W_500),
            on_click=self.save_settings,
            width=150,
        )
        
        self.clear_button = OutlinedButton(
            content=Text("Очистить историю"),
            on_click=self.show_clear_dialog,
            width=200,
        )
        
        self.controls = [
            self.app_bar,
            
            # Appearance Section
            Card(
                content=Container(
                    content=Column([
                        Text("Внешний вид", size=18, weight=ft.FontWeight.W_600),
                        Container(height=5),
                        self.theme_buttons,
                        Container(height=5),
                        self.current_theme,
                    ], spacing=5),
                    padding=20,
                ),
                elevation=1,
            ),
            
            Container(height=15),
            
            # AI Personality Section
            Card(
                content=Container(
                    content=Column([
                        Text("Личность ИИ", size=18, weight=ft.FontWeight.W_600),
                        Container(height=5),
                        self.system_prompt_field,
                        Container(height=10),
                        self.save_button,
                    ], spacing=5),
                    padding=20,
                ),
                elevation=1,
            ),
            
            Container(height=15),
            
            # Очистка Section
            Card(
                content=Container(
                    content=Column([
                        Text("Очистка", size=18, weight=ft.FontWeight.W_600),
                        Container(height=10),
                        self.clear_button,
                    ], spacing=5),
                    padding=20,
                ),
                elevation=1,
            ),
            
            Container(height=15),
            
            # About Section
            Card(
                content=Container(
                    content=Column([
                        Text("О приложении", size=18, weight=ft.FontWeight.W_600),
                        Container(height=5),
                        Text("AI Companion", size=16, weight=ft.FontWeight.W_500),
                        Text("Версия 1.0.0", size=14, color=ft.Colors.ON_SURFACE_VARIANT),
                        Container(height=5),
                        Text("Локальный ИИ помощник с поддержкой Gemma 3", size=12, color=ft.Colors.ON_SURFACE_VARIANT),
                    ], spacing=5),
                    padding=20,
                ),
                elevation=1,
            ),
            
            Container(height=30),
        ]
        
        self.spacing = 10
        self.padding = 20
        self.scroll = ft.ScrollMode.AUTO
        self.horizontal_alignment = ft.CrossAxisAlignment.CENTER
        self.expand = True

    def get_text(self, key: str) -> str:
        from ..i18n import get_translation
        return get_translation(self.lang, key)

    def go_back(self, e=None):
        if self.app:
            self.app.set_screen(0)
            self.app.page.update()

    async def load_settings(self):
        self.settings = await self.services.db.get_settings()
        if self.settings:
            self.system_prompt_field.value = self.settings.system_prompt
            theme_names = {"light": "Светлая", "dark": "Тёмная", "system": "Системная"}
            self.current_theme.value = f"Тема: {theme_names.get(self.settings.theme, 'Системная')}"
        self._page.update()

    def change_theme(self, theme):
        if self.app:
            self.app.setup_theme(theme)
        theme_names = {"light": "Светлая", "dark": "Тёмная", "system": "Системная"}
        self.current_theme.value = f"Тема: {theme_names.get(theme, 'Системная')}"
        
        if self.settings:
            self.settings.theme = theme
            from asyncio import create_task
            create_task(self.services.db.update_settings(self.settings))
        
        self._page.update()

    async def save_settings(self, e=None):
        if self.settings:
            self.settings.system_prompt = self.system_prompt_field.value
            await self.services.db.update_settings(self.settings)
            self.services.ai.set_system_prompt(self.settings.system_prompt)
        
        print("Settings saved!")

    async def show_clear_dialog(self, e=None):
        await self.services.db.clear_all_messages()
        if self.app and hasattr(self.app, 'chat_screen'):
            self.app.chat_screen.messages = []
            self.app.chat_screen.messages_list.controls.clear()
            self.app.chat_screen._page.update()
        print("History cleared")
        self._page.update()
