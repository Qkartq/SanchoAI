import os
from typing import Generator, Optional, List
from ..models.schemas import Message


class ModelStatus:
    LOADING = "loading"
    READY = "ready"
    IDLE = "idle"
    GENERATING = "generating"


class AIService:
    def __init__(self, model_path: str = None):
        self.model_path = model_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "google_gemma-3-1b-it-Q5_K_M.gguf"
        )
        self.model = None
        self._is_ready = False
        self.status = ModelStatus.LOADING
        self._status_callback = None

    def set_status_callback(self, callback):
        self._status_callback = callback

    def _update_status(self, status: str):
        self.status = status
        if self._status_callback:
            self._status_callback(status)

    def initialize(self):
        try:
            from llama_cpp import Llama
            n_ctx = 1024
            n_threads = 4
            
            self._update_status(ModelStatus.LOADING)
            
            self.model = Llama(
                model_path=self.model_path,
                n_ctx=n_ctx,
                n_threads=n_threads,
                n_gpu_layers=0,
                verbose=False,
            )
            self._is_ready = True
            self._update_status(ModelStatus.READY)
            print(f"Model loaded: {self.model_path}")
        except Exception as e:
            print(f"Error loading model: {e}")
            self._is_ready = False
            self._update_status(ModelStatus.IDLE)

    def set_system_prompt(self, prompt: str):
        self.system_prompt = prompt

    def check_connection(self) -> bool:
        return self._is_ready
    
    def get_status(self) -> str:
        return self.status

    async def generate(self, message: str, conversation_history: List[Message] = None) -> str:
        if not self._is_ready or not self.model:
            return "Error: AI model not loaded. Please restart the app."

        self._update_status(ModelStatus.GENERATING)

        messages = []
        
        if hasattr(self, 'system_prompt') and self.system_prompt:
            messages.append({"role": "system", "content": self.system_prompt})
        
        if conversation_history:
            prev_role = None
            for msg in conversation_history:
                if msg.role != prev_role:
                    messages.append({"role": msg.role, "content": msg.content})
                    prev_role = msg.role
        
        messages.append({"role": "user", "content": message})

        try:
            output = self.model.create_chat_completion(
                messages=messages,
                temperature=0.7,
                max_tokens=512,
                stream=False,
            )
            self._update_status(ModelStatus.READY)
            return output["choices"][0]["message"]["content"]
        except Exception as e:
            self._update_status(ModelStatus.READY)
            error_msg = str(e)
            if "context window" in error_msg.lower() or "tokens" in error_msg.lower():
                return "__CONTEXT_LIMIT__"
            return f"Error: {error_msg}"

    async def summarize_conversation(self, conversation_history: List[Message]) -> str:
        if not conversation_history:
            return ""
        
        self._update_status(ModelStatus.GENERATING)
        
        summary_prompt = """Создай краткое содержание (резюме) нашего разговора. 
Выдели основные темы, вопросы и ответы. 
Резюме должно быть информативным и содержать суть диалога.

История разговора:
"""
        
        for msg in conversation_history:
            role_emoji = "👤" if msg.role == "user" else "🤖"
            summary_prompt += f"\n{role_emoji} {msg.content}"
        
        summary_prompt += "\n\nКраткое содержание разговора:"
        
        try:
            output = self.model.create_chat_completion(
                messages=[{"role": "user", "content": summary_prompt}],
                temperature=0.5,
                max_tokens=256,
                stream=False,
            )
            summary = output["choices"][0]["message"]["content"]
            self._update_status(ModelStatus.READY)
            return summary
        except Exception as e:
            self._update_status(ModelStatus.READY)
            print(f"Summary error: {e}")
            return "Краткое содержание недоступно."

    async def generate_stream(self, message: str, conversation_history: List[Message] = None) -> Generator[str, None, None]:
        if not self._is_ready or not self.model:
            yield "Error: AI model not loaded."
            return

        self._update_status(ModelStatus.GENERATING)

        messages = []
        if hasattr(self, 'system_prompt') and self.system_prompt:
            messages.append({"role": "system", "content": self.system_prompt})
        
        if conversation_history:
            for msg in conversation_history:
                messages.append({"role": msg.role, "content": msg.content})
        
        messages.append({"role": "user", "content": message})

        try:
            output = self.model.create_chat_completion(
                messages=messages,
                temperature=0.7,
                max_tokens=512,
                stream=True,
            )
            for chunk in output:
                content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
                if content:
                    yield content
            self._update_status(ModelStatus.READY)
        except Exception as e:
            self._update_status(ModelStatus.READY)
            yield f"Error: {str(e)}"

    async def analyze_document(self, content: str, question: str = "Summarize this document") -> str:
        prompt = f"""Based on the following document content, {question}

Document:
{content[:5000]}

Please provide a helpful response:"""

        return await self.generate(prompt)

    async def analyze_image(self, extracted_text: str, description: str = "") -> str:
        prompt = f"""Analyze this image.

"""
        if extracted_text:
            prompt += f"Extracted text from image:\n{extracted_text}\n\n"
        if description:
            prompt += f"Visual description: {description}\n\n"
        
        prompt += "Provide a detailed analysis of what you see and any text content found."
        
        return await self.generate(prompt)

    def get_available_models(self) -> list:
        return [os.path.basename(self.model_path)] if os.path.exists(self.model_path) else []
