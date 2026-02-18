import json
import os


def get_system_language() -> str:
    try:
        import locale
        lang = locale.getdefaultlocale()[0] or "en"
        if lang.startswith("ru"):
            return "ru"
        return "en"
    except:
        return "en"


def save_json(data: dict, filepath: str) -> bool:
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        print(f"Error saving JSON: {e}")
        return False


def load_json(filepath: str) -> dict:
    try:
        if os.path.exists(filepath):
            with open(filepath, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
    return {}


def get_app_dir() -> str:
    import os
    app_dir = os.path.join(os.path.expanduser("~"), ".ai_companion")
    os.makedirs(app_dir, exist_ok=True)
    return app_dir
