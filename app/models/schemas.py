from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class Message(BaseModel):
    id: Optional[int] = None
    role: str  # "user" or "assistant"
    content: str
    timestamp: Optional[datetime] = None
    conversation_id: int = 1


class Conversation(BaseModel):
    id: Optional[int] = None
    title: str = "New Chat"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class AppSettings(BaseModel):
    id: int = 1
    system_prompt: str = "You are a helpful AI assistant."
    language: str = "auto"  # auto, ru, en
    theme: str = "system"  # system, light, dark
