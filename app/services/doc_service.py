import io
from typing import Optional
from pypdf import PdfReader
from docx import Document


class DocumentService:
    def extract_text_from_pdf(self, file_path: str) -> str:
        try:
            reader = PdfReader(file_path)
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
            return text.strip()
        except Exception as e:
            return f"Error reading PDF: {str(e)}"

    def extract_text_from_docx(self, file_path: str) -> str:
        try:
            doc = Document(file_path)
            text = ""
            for para in doc.paragraphs:
                text += para.text + "\n"
            return text.strip()
        except Exception as e:
            return f"Error reading DOCX: {str(e)}"

    def extract_text(self, file_path: str) -> str:
        if file_path.lower().endswith(".pdf"):
            return self.extract_text_from_pdf(file_path)
        elif file_path.lower().endswith(".docx"):
            return self.extract_text_from_docx(file_path)
        elif file_path.lower().endswith(".txt"):
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        elif file_path.lower().endswith(".md"):
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        else:
            return "Unsupported file format"

    def get_file_info(self, file_path: str) -> dict:
        import os
        stat = os.stat(file_path)
        return {
            "name": os.path.basename(file_path),
            "size": stat.st_size,
            "extension": os.path.splitext(file_path)[1].lower()
        }
