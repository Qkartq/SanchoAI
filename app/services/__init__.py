from .db_service import DBService
from .ai_service import AIService
from .doc_service import DocumentService
from .ocr_service import OCRService
from .notification_service import NotificationService


class AppServices:
    def __init__(self):
        self.db = DBService()
        self.ai = AIService()
        self.doc = DocumentService()
        self.ocr = OCRService()
        self.notifications = NotificationService()

    async def initialize(self):
        await self.db.connect()
        settings = await self.db.get_settings()
        self.ai.set_system_prompt(settings.system_prompt)

    async def cleanup(self):
        await self.db.close()
