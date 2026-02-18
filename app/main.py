import flet as ft
from flet import NavigationBar, NavigationBarDestination, Column, Container
import asyncio
from app.services import AppServices
from app.screens import ChatScreen, SettingsScreen
from app.utils.helpers import get_system_language


class AICompanionApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.services = AppServices()
        self.lang = "en"
        
        page.title = "AI Companion"
        page.theme_mode = ft.ThemeMode.SYSTEM
        page.padding = 0
        
        self.setup_theme()
        
        self.chat_screen = ChatScreen(page, self.services, self.lang)
        self.settings_screen = SettingsScreen(page, self.services, self.lang, self)
        
        self.current_screen = self.chat_screen
        
        self.navigation_bar = NavigationBar(
            selected_index=0,
            destinations=[
                NavigationBarDestination(icon=ft.Text("💬"), label="Chat"),
                NavigationBarDestination(icon=ft.Text("⚙️"), label="Settings"),
            ],
            on_change=self.on_navigation_change,
        )
        
        self.main_column = Column([
            self.current_screen,
        ], expand=True, spacing=0)
        
        page.add(self.main_column)
        page.add(self.navigation_bar)
        
        page.on_view_pop = self.handle_back

    def setup_theme(self, theme_mode=None):
        if theme_mode == "light":
            self.page.theme_mode = ft.ThemeMode.LIGHT
        elif theme_mode == "dark":
            self.page.theme_mode = ft.ThemeMode.DARK
        else:
            self.page.theme_mode = ft.ThemeMode.SYSTEM
        
        self.page.theme = ft.Theme(
            color_scheme_seed=ft.Colors.INDIGO,
            use_material3=True,
        )

    def set_screen(self, index: int):
        if self.current_screen in self.main_column.controls:
            self.main_column.controls.remove(self.current_screen)
        
        if index == 0:
            self.current_screen = self.chat_screen
        elif index == 1:
            self.current_screen = self.settings_screen
            asyncio.create_task(self.settings_screen.load_settings())
        
        self.navigation_bar.selected_index = index
        self.main_column.controls.append(self.current_screen)

    def on_navigation_change(self, e):
        self.set_screen(e.control.selected_index)
        self.page.update()

    def handle_back(self, e):
        self.set_screen(0)
        self.page.update()


async def main(page: ft.Page):
    app = AICompanionApp(page)
    await app.services.initialize()
    app.services.notifications.set_page(page)
    
    app.services.ai.initialize()
    print("AI model initialized" if app.services.ai.check_connection() else "AI model NOT loaded")
    
    settings = await app.services.db.get_settings()
    if settings.language == "auto":
        app.lang = get_system_language()
    else:
        app.lang = settings.language
    
    app.setup_theme(settings.theme)
    app.chat_screen.lang = app.lang
    app.settings_screen.lang = app.lang
    
    await app.chat_screen.load_messages()


ft.app(target=main)
