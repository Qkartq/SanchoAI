from PIL import Image
import io
from typing import Optional


class OCRService:
    def __init__(self):
        self.processor = None
        self.model = None

    async def initialize(self):
        try:
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel
            self.processor = TrOCRProcessor.from_pretrained("microsoft/trocr-base-handwritten")
            self.model = VisionEncoderDecoderModel.from_pretrained("microsoft/trocr-base-handwritten")
        except Exception as e:
            print(f"OCR init error: {e}")

    def extract_text_from_image(self, image_path: str) -> str:
        try:
            if not self.model or not self.processor:
                return "OCR model not loaded"

            image = Image.open(image_path).convert("RGB")
            pixel_values = self.processor(images=image, return_tensors="pt").pixel_values
            generated_ids = self.model.generate(pixel_values)
            generated_text = self.processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            return generated_text
        except Exception as e:
            return f"OCR Error: {str(e)}"

    def get_image_description(self, image_path: str) -> str:
        try:
            from transformers import pipeline
            captioner = pipeline("image-captioning", model="Salesforce/blip-image-captioning-base")
            result = captioner(image_path)
            return result[0]["caption"] if result else "No description"
        except Exception as e:
            return f"Description Error: {str(e)}"

    async def analyze_image(self, image_path: str) -> dict:
        text = self.extract_text_from_image(image_path)
        description = self.get_image_description(image_path)
        
        return {
            "extracted_text": text,
            "description": description
        }
