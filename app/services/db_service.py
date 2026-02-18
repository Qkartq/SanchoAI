import aiosqlite
import os
from datetime import datetime
from typing import List, Optional
from ..models.schemas import Message, Conversation, AppSettings
from ..utils.helpers import get_app_dir


class DBService:
    def __init__(self):
        self.db_path = os.path.join(get_app_dir(), "ai_companion.db")
        self._connection = None

    async def connect(self):
        self._connection = await aiosqlite.connect(self.db_path)
        await self._create_tables()

    async def _create_tables(self):
        await self._connection.execute("""
            CREATE TABLE IF NOT EXISTS conversations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)
        await self._connection.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                conversation_id INTEGER NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                FOREIGN KEY (conversation_id) REFERENCES conversations (id)
            )
        """)
        await self._connection.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY,
                system_prompt TEXT NOT NULL,
                language TEXT NOT NULL,
                theme TEXT NOT NULL
            )
        """)
        await self._connection.commit()

        cursor = await self._connection.execute("SELECT COUNT(*) FROM settings")
        if (await cursor.fetchone())[0] == 0:
            await self._connection.execute(
                "INSERT INTO settings (id, system_prompt, language, theme) VALUES (?, ?, ?, ?)",
                (1, "You are a helpful AI assistant.", "auto", "system")
            )
            await self._connection.commit()

    async def get_settings(self) -> AppSettings:
        cursor = await self._connection.execute(
            "SELECT id, system_prompt, language, theme FROM settings WHERE id = 1"
        )
        row = await cursor.fetchone()
        if row:
            return AppSettings(
                id=row[0],
                system_prompt=row[1],
                language=row[2],
                theme=row[3]
            )
        return AppSettings()

    async def update_settings(self, settings: AppSettings):
        await self._connection.execute(
            "UPDATE settings SET system_prompt = ?, language = ?, theme = ? WHERE id = 1",
            (settings.system_prompt, settings.language, settings.theme)
        )
        await self._connection.commit()

    async def create_conversation(self, title: str = "New Chat") -> Conversation:
        now = datetime.now().isoformat()
        cursor = await self._connection.execute(
            "INSERT INTO conversations (title, created_at, updated_at) VALUES (?, ?, ?)",
            (title, now, now)
        )
        await self._connection.commit()
        return Conversation(id=cursor.lastrowid, title=title, created_at=now, updated_at=now)

    async def get_conversations(self) -> List[Conversation]:
        cursor = await self._connection.execute(
            "SELECT id, title, created_at, updated_at FROM conversations ORDER BY updated_at DESC"
        )
        rows = await cursor.fetchall()
        return [Conversation(id=r[0], title=r[1], created_at=r[2], updated_at=r[3]) for r in rows]

    async def get_conversation(self, conversation_id: int) -> Optional[Conversation]:
        cursor = await self._connection.execute(
            "SELECT id, title, created_at, updated_at FROM conversations WHERE id = ?",
            (conversation_id,)
        )
        row = await cursor.fetchone()
        if row:
            return Conversation(id=row[0], title=row[1], created_at=row[2], updated_at=row[3])
        return None

    async def delete_conversation(self, conversation_id: int):
        await self._connection.execute("DELETE FROM messages WHERE conversation_id = ?", (conversation_id,))
        await self._connection.execute("DELETE FROM conversations WHERE id = ?", (conversation_id,))
        await self._connection.commit()

    async def add_message(self, message: Message) -> Message:
        timestamp = message.timestamp or datetime.now().isoformat()
        cursor = await self._connection.execute(
            "INSERT INTO messages (conversation_id, role, content, timestamp) VALUES (?, ?, ?, ?)",
            (message.conversation_id, message.role, message.content, timestamp)
        )
        await self._connection.commit()

        await self._connection.execute(
            "UPDATE conversations SET updated_at = ? WHERE id = ?",
            (timestamp, message.conversation_id)
        )
        await self._connection.commit()

        return Message(id=cursor.lastrowid, **message.dict(exclude={"id"}))

    async def get_messages(self, conversation_id: int) -> List[Message]:
        cursor = await self._connection.execute(
            "SELECT id, conversation_id, role, content, timestamp FROM messages WHERE conversation_id = ? ORDER BY timestamp ASC",
            (conversation_id,)
        )
        rows = await cursor.fetchall()
        return [Message(id=r[0], conversation_id=r[1], role=r[2], content=r[3], timestamp=r[4]) for r in rows]

    async def clear_all_messages(self):
        await self._connection.execute("DELETE FROM messages")
        await self._connection.execute("DELETE FROM conversations")
        await self._connection.commit()
    
    async def clear_conversation_messages(self, conversation_id: int):
        await self._connection.execute("DELETE FROM messages WHERE conversation_id = ?", (conversation_id,))
        await self._connection.commit()

    async def export_conversation_json(self, conversation_id: int) -> dict:
        conv = await self.get_conversation(conversation_id)
        messages = await self.get_messages(conversation_id)
        return {
            "conversation": conv.dict() if conv else {},
            "messages": [m.dict() for m in messages]
        }

    async def close(self):
        if self._connection:
            await self._connection.close()
