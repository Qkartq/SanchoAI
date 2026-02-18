import flet as ft
from flet import Column, ListView, TextField, IconButton, Container, Row, Button, ProgressRing
from datetime import datetime
from ..models.schemas import Message
from ..widgets.message_bubble import MessageBubble, LoadingIndicator


class ChatScreen(Column):
    def __init__(self, pg, services, lang: str = "en", **kwargs):
        super().__init__(**kwargs)
        self.services = services
        self.lang = lang
        self.messages = []
        self.conversation_id = 1
        self.is_loading = False
        self._page = pg
        
        self.messages_list = ListView(
            expand=True,
            spacing=10,
            padding=10,
        )
        
        self.input_field = TextField(
            hint_text="Type a message...",
            multiline=True,
            max_lines=3,
            expand=True,
            on_submit=self.send_message,
        )
        
        self.send_button = IconButton(
            icon=ft.Text("⬆️", size=20),
            on_click=self.send_message,
        )
        
        self.loading_indicator = None
        self.processing_indicator = None
        
        self.controls = [
            self.messages_list,
            Container(
                content=Row([
                    self.input_field,
                    self.send_button,
                ], spacing=5),
                padding=10,
                border=ft.border.only(top=ft.border.BorderSide(1, ft.Colors.OUTLINE)),
            )
        ]
        
        self.expand = True

    def get_text(self, key: str) -> str:
        from ..i18n import get_translation
        return get_translation(self.lang, key)

    async def load_messages(self):
        self.messages = await self.services.db.get_messages(self.conversation_id)
        self.messages_list.controls.clear()
        
        for msg in self.messages:
            self.messages_list.controls.append(
                MessageBubble(role=msg.role, content=msg.content)
            )
        
        self._page.update()

    async def scroll_to_bottom(self):
        if self.messages_list.controls:
            await self.messages_list.scroll_to(offset=len(self.messages_list.controls) - 1, duration=300)

    async def send_message(self, e=None):
        user_text = self.input_field.value.strip()
        
        if not user_text or self.is_loading:
            return
        
        self.input_field.value = ""
        self.is_loading = True
        
        user_message = Message(
            role="user",
            content=user_text,
            conversation_id=self.conversation_id
        )
        
        saved_message = await self.services.db.add_message(user_message)
        self.messages.append(saved_message)
        
        self.messages_list.controls.append(
            MessageBubble(role="user", content=user_text)
        )
        
        self.loading_indicator = LoadingIndicator(self.get_text("thinking"))
        self.messages_list.controls.append(self.loading_indicator)
        
        self.processing_indicator = Container(
            content=Row([
                ProgressRing(width=16, height=16),
                ft.Text(self.get_text("thinking"), size=12, color=ft.Colors.PRIMARY)
            ], spacing=5),
            padding=5,
        )
        self.messages_list.controls.append(self.processing_indicator)
        
        self._page.update()
        
        conversation_history = self.messages[:-1]
        
        try:
            response = await self.services.ai.generate(user_text, conversation_history)
            
            if self.loading_indicator:
                self.messages_list.controls.remove(self.loading_indicator)
                self.loading_indicator = None
            
            if self.processing_indicator:
                self.messages_list.controls.remove(self.processing_indicator)
                self.processing_indicator = None
            
            assistant_message = Message(
                role="assistant",
                content=response,
                conversation_id=self.conversation_id
            )
            
            saved_assistant = await self.services.db.add_message(assistant_message)
            self.messages.append(saved_assistant)
            
            self.messages_list.controls.append(
                MessageBubble(role="assistant", content=response)
            )
            
            self.services.notifications.show_local_notification(
                self.get_text("notification_title"),
                self.get_text("notification_body")
            )
            
        except Exception as ex:
            if self.loading_indicator:
                self.messages_list.controls.remove(self.loading_indicator)
            if self.processing_indicator:
                self.messages_list.controls.remove(self.processing_indicator)
            
            error_msg = f"Error: {str(ex)}"
            self.messages_list.controls.append(
                MessageBubble(role="assistant", content=error_msg)
            )
        
        self.is_loading = False
        self._page.update()
