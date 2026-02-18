import flet as ft
from flet import Page, SnackBar, Text, Column, FontWeight


class NotificationService:
    def __init__(self, page: Page = None):
        self.page = page

    def set_page(self, page: Page):
        self.page = page

    def show_local_notification(self, title: str, body: str):
        if self.page:
            try:
                snack = SnackBar(
                    content=Text(body),
                    duration=3000,
                )
                self.page.show_snack_bar(snack)
            except:
                pass

    def show_in_app_notification(self, title: str, message: str):
        if self.page:
            self.page.show_snack_bar(
                SnackBar(
                    content=Column([
                        Text(title, weight=FontWeight.BOLD),
                        Text(message)
                    ]),
                    duration=4000,
                    background_color=ft.Colors.SURFACE_CONTAINER_HIGH
                )
            )
