import flet as ft
from flet import Column, ListView, TextField, Container, Row, FilledButton, ProgressBar, AppBar, IconButton, Text
from datetime import datetime
import asyncio
from ..models.schemas import Message
from ..widgets.message_bubble import MessageBubble, LoadingIndicator


class ChatScreen(Column):
    def __init__(self, pg, services, lang: str = "en", app=None, **kwargs):
        super().__init__(**kwargs)
        self.services = services
        self.lang = lang
        self.messages = []
        self.conversation_id = 1
        self.is_loading = False
        self._page = pg
        self.app = app
        self._last_assistant_bubble = None
        self._last_response = None
        self._continue_btn_container = None
        
        self.app_bar = AppBar(
            title=Text("AI Companion", size=20, weight=ft.FontWeight.W_500),
            leading=IconButton(
                icon=ft.Icon(ft.Icons.SETTINGS, size=24),
                on_click=self.open_settings,
                tooltip="Настройки",
            ),
            leading_width=48,
            elevation=1,
            bgcolor=ft.Colors.SURFACE,
        )
        
        self.messages_list = ListView(
            expand=True,
            spacing=10,
            padding=10,
        )
        
        self.input_field = TextField(
            hint_text="Напишите сообщение...",
            multiline=True,
            max_lines=4,
            expand=True,
            filled=True,
            border_color=ft.Colors.PRIMARY,
            cursor_color=ft.Colors.PRIMARY,
            text_style=ft.TextStyle(size=15),
            hint_style=ft.TextStyle(color=ft.Colors.ON_SURFACE_VARIANT),
            on_submit=self.send_message,
        )
        
        self.send_button = FilledButton(
            content=Text("Отправить", weight=ft.FontWeight.W_500),
            on_click=self.send_message,
            style=ft.ButtonStyle(
                padding=ft.padding.symmetric(horizontal=16, vertical=12),
            ),
        )
        
        self.loading_indicator = None
        
        self.controls = [
            self.app_bar,
            self.messages_list,
            Container(
                content=Row([
                    self.input_field,
                    self.send_button,
                ], spacing=8, vertical_alignment=ft.CrossAxisAlignment.END),
                padding=15,
                bgcolor=ft.Colors.SURFACE_CONTAINER_HIGH,
                border=ft.border.only(top=ft.border.BorderSide(1, ft.Colors.OUTLINE_VARIANT)),
            )
        ]
        
        self.expand = True

    def get_text(self, key: str) -> str:
        from ..i18n import get_translation
        return get_translation(self.lang, key)

    def open_settings(self, e=None):
        if self.app:
            self.app.set_screen(1)
            self.app.page.update()

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

    async def _continue_generation(self):
        print(f"Continue generation called, is_loading={self.is_loading}")
        if self.is_loading or not self._last_assistant_bubble:
            return
        
        self.is_loading = True
        current_response = self._last_response
        assistant_bubble = self._last_assistant_bubble
        continue_btn_container = self._continue_btn_container
        
        if self.app and hasattr(self.app, 'status_bar'):
            self.app.status_bar.set_status("generating")
            self._page.update()
        
        await asyncio.sleep(0.01)
        
        try:
            response = await self.services.ai.continue_generation(self.messages)
            print(f"Continue response: {response[:100] if response else 'empty'}...")
            
            if current_response:
                new_content = current_response.rstrip() + "\n\n" + response
            else:
                new_content = response
            
            if assistant_bubble in self.messages_list.controls:
                self.messages_list.controls.remove(assistant_bubble)
            
            new_bubble = MessageBubble(role="assistant", content=new_content)
            self.messages_list.controls.append(new_bubble)
            
            self._last_assistant_bubble = new_bubble
            self._last_response = new_content
            
            if continue_btn_container and continue_btn_container in self.messages_list.controls:
                self.messages_list.controls.remove(continue_btn_container)
            
            async def on_continue_click(e):
                if self._last_assistant_bubble:
                    await self._continue_generation()
            
            new_continue_btn = ft.Container(
                content=ft.TextButton(
                    content=ft.Row([
                        ft.Icon(ft.Icons.REPLAY, size=16),
                        ft.Text("Продолжить", size=12),
                    ], spacing=4),
                    on_click=on_continue_click,
                ),
                alignment=ft.Alignment(-1, 0),
                margin=ft.margin.only(left=0, right=50),
            )
            self._continue_btn_container = new_continue_btn
            self.messages_list.controls.append(new_continue_btn)
            
            assistant_message = Message(
                role="assistant",
                content=new_content,
                conversation_id=self.conversation_id
            )
            
            self.messages[-1] = assistant_message
            await self.services.db.update_message(self.messages[-1].id, new_content)
            
        except Exception as ex:
            print(f"Continue generation error: {ex}")
        
        if self.app and hasattr(self.app, 'status_bar'):
            self.app.status_bar.set_status("ready")
            self._page.update()
        
        self.is_loading = False
        await self.scroll_to_bottom()
        self._page.update()

    async def send_message(self, e=None):
        user_text = self.input_field.value.strip()
        
        if not user_text or self.is_loading:
            return
        
        self.input_field.value = ""
        self.input_field.update()
        self.is_loading = True
        
        user_message = Message(
            role="user",
            content=user_text,
            conversation_id=self.conversation_id
        )
        
        saved_message = await self.services.db.add_message(user_message)
        self.messages.append(saved_message)
        
        if self._continue_btn_container:
            if self._continue_btn_container in self.messages_list.controls:
                self.messages_list.controls.remove(self._continue_btn_container)
            self._continue_btn_container = None
            self._last_assistant_bubble = None
            self._last_response = None
        
        user_bubble = MessageBubble(role="user", content=user_text)
        self.messages_list.controls.append(user_bubble)
        
        self.loading_indicator = LoadingIndicator(self.get_text("thinking"))
        self.messages_list.controls.append(self.loading_indicator)
        
        await self.scroll_to_bottom()
        self._page.update()
        
        if self.app and hasattr(self.app, 'status_bar'):
            self.app.status_bar.set_status("generating")
            self._page.update()
        
        await asyncio.sleep(0.01)
        
        conversation_history = self.messages[:-1]
        
        try:
            response = await self.services.ai.generate(user_text, conversation_history)
            
            if self.loading_indicator:
                self.messages_list.controls.remove(self.loading_indicator)
                self.loading_indicator = None
            
            if self.app and hasattr(self.app, 'status_bar'):
                self.app.status_bar.set_status("ready")
                self._page.update()
            
            if response == "__CONTEXT_LIMIT__":
                if user_bubble in self.messages_list.controls:
                    self.messages_list.controls.remove(user_bubble)
                
                summary = await self.services.ai.summarize_conversation(self.messages)
                
                await self.services.db.clear_conversation_messages(self.conversation_id)
                
                summary_message = Message(
                    role="assistant",
                    content=f"📝 Краткое содержание предыдущего разговора:\n\n{summary}\n\n--- Разговор продолжается ---",
                    conversation_id=self.conversation_id
                )
                await self.services.db.add_message(summary_message)
                
                self.messages = [summary_message]
                self.messages_list.controls.clear()
                self.messages_list.controls.append(
                    MessageBubble(role="assistant", content=summary_message.content)
                )
                
                response = await self.services.ai.generate(user_text, [summary_message])
            
            assistant_message = Message(
                role="assistant",
                content=response,
                conversation_id=self.conversation_id
            )
            
            saved_assistant = await self.services.db.add_message(assistant_message)
            self.messages.append(saved_assistant)
            
            assistant_bubble = MessageBubble(role="assistant", content=response)
            self.messages_list.controls.append(assistant_bubble)
            
            self._last_assistant_bubble = assistant_bubble
            self._last_response = response
            
            async def on_continue_click(e):
                if self._last_assistant_bubble:
                    await self._continue_generation()
            
            continue_btn_container = ft.Container(
                content=ft.TextButton(
                    content=ft.Row([
                        ft.Icon(ft.Icons.REPLAY, size=16),
                        ft.Text("Продолжить", size=12),
                    ], spacing=4),
                    on_click=on_continue_click,
                ),
                alignment=ft.Alignment(-1, 0),
                margin=ft.margin.only(left=0, right=50),
            )
            self._continue_btn_container = continue_btn_container
            self.messages_list.controls.append(continue_btn_container)
            
            self.services.notifications.show_local_notification(
                self.get_text("notification_title"),
                self.get_text("notification_body")
            )
            
        except Exception as ex:
            if self.loading_indicator:
                self.messages_list.controls.remove(self.loading_indicator)
                self.loading_indicator = None
            
            if self.app and hasattr(self.app, 'status_bar'):
                self.app.status_bar.set_status("ready")
                self._page.update()
            
            error_msg = f"Error: {str(ex)}"
            self.messages_list.controls.append(
                MessageBubble(role="assistant", content=error_msg)
            )
        
        self.is_loading = False
        await self.scroll_to_bottom()
        self._page.update()
