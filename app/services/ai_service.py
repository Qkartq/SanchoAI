import os
from typing import Generator, Optional, List
from ..models.schemas import Message


class AIService:
    def __init__(self, model_path: str = None):
        self.model_path = model_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "google_gemma-3-1b-it-Q5_K_M.gguf"
        )
        self.model = None
        self._is_ready = False

    def initialize(self):
        try:
            from llama_cpp import Llama
            n_ctx = 2048
            n_threads = 4
            
            self.model = Llama(
                model_path=self.model_path,
                n_ctx=n_ctx,
                n_threads=n_threads,
                n_gpu_layers=0,
                verbose=False,
            )
            self._is_ready = True
            print(f"Model loaded: {self.model_path}")
        except Exception as e:
            print(f"Error loading model: {e}")
            self._is_ready = False

    def set_system_prompt(self, prompt: str):
        self.system_prompt = prompt

    def check_connection(self) -> bool:
        return self._is_ready

    async def generate(self, message: str, conversation_history: List[Message] = None) -> str:
        if not self._is_ready or not self.model:
            return "Error: AI model not loaded. Please restart the app."

        messages = []
        
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
            return output["choices"][0]["message"]["content"]
        except Exception as e:
            return f"Error: {str(e)}"

    async def generate_stream(self, message: str, conversation_history: List[Message] = None) -> Generator[str, None, None]:
        if not self._is_ready or not self.model:
            yield "Error: AI model not loaded."
            return

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
        except Exception as e:
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
