# AI Companion

<div align="center">

![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square)
![Flet](https://img.shields.io/badge/Flet-0.80+-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Android](https://img.shields.io/badge/Platform-Android-green?style=flat-square)

A local AI companion app for Android that works offline, built with Python and Flet.

[English](#english) | [Русский](#русский)

---

</div>

<a name="english"></a>

## English

### Features

- 💬 **Chat with AI** - Conversational AI powered by local GGUF models
- 📄 **Document Analysis** - Extract and analyze text from PDF, DOCX files
- 🖼️ **Image Analysis** - OCR and image description capabilities
- 🌙 **Theme Support** - Light, Dark, and System theme modes
- 🌍 **Multilingual** - Russian and English interface
- 💾 **History** - Persistent chat history with SQLite
- ⚙️ **Customizable** - Configure AI personality via system prompt
- 📤 **Export** - Export conversations to JSON

### Requirements

- Python 3.10+
- 4GB+ RAM (6GB+ recommended)
- Android 8.0+ (for APK)
- GGUF model file (included)

### Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the app:
```bash
python main.py
```

### Building APK

Prerequisites: Flutter SDK must be installed.

```bash
flet build apk sanchoAI --project AICompanion --org com.aicompanion
```

### Project Structure

```
sanchoAI/
├── app/
│   ├── main.py              # App entry point
│   ├── screens/             # UI screens
│   │   ├── chat.py        # Main chat screen
│   │   └── settings.py     # Settings screen
│   ├── services/           # Business logic
│   │   ├── ai_service.py   # AI model inference
│   │   ├── db_service.py  # SQLite database
│   │   └── doc_service.py # Document parsing
│   ├── widgets/            # Reusable UI components
│   ├── models/            # Data models
│   ├── i18n/              # Internationalization
│   └── utils/             # Utilities
├── google_gemma-3-1b-it-Q5_K_M.gguf  # AI Model
├── requirements.txt
└── main.py
```

### Configuration

- **AI Model**: Uses Gemma 3B GGUF model (Q5_K_M quantization)
- **Database**: SQLite stored in `~/.ai_companion/`
- **Theme**: System/Light/Dark via settings
- **Language**: Auto-detected or manual in settings

### License

MIT License - See LICENSE file for details.

---

<a name="русский"></a>

## Русский

### Функции

- 💬 **Чат с AI** - Разговорный AI на основе локальной GGUF модели
- 📄 **Анализ документов** - Извлечение и анализ текста из PDF, DOCX
- 🖼️ **Анализ изображений** - OCR и описание изображений
- 🌙 **Темы** - Светлая, тёмная и системная темы
- 🌍 **Многоязычность** - Русский и английский интерфейс
- 💾 **История** - Сохранение истории чата в SQLite
- ⚙️ **Настройка** - Изменение личности AI через system prompt
- 📤 **Экспорт** - Экспорт диалогов в JSON

### Требования

- Python 3.10+
- 4GB+ RAM (рекомендуется 6GB+)
- Android 8.0+ (для APK)
- GGUF файл модели (включён)

### Установка

1. Установите зависимости:
```bash
pip install -r requirements.txt
```

2. Запустите приложение:
```bash
python main.py
```

### Сборка APK

Требование: Flutter SDK должен быть установлен.

```bash
flet build apk sanchoAI --project AICompanion --org com.aicompanion
```

### Структура проекта

```
sanchoAI/
├── app/
│   ├── main.py              # Точка входа
│   ├── screens/             # Экраны UI
│   │   ├── chat.py        # Экран чата
│   │   └── settings.py     # Настройки
│   ├── services/           # Бизнес-логика
│   │   ├── ai_service.py   # AI модель
│   │   ├── db_service.py  # SQLite БД
│   │   └── doc_service.py # Документы
│   ├── widgets/            # UI компоненты
│   ├── models/             # Модели данных
│   ├── i18n/              # Переводы
│   └── utils/             # Утилиты
├── google_gemma-3-1b-it-Q5_K_M.gguf  # AI модель
├── requirements.txt
└── main.py
```

### Настройка

- **AI Модель**: Gemma 3B GGUF (Q5_K_M квантование)
- **База данных**: SQLite в `~/.ai_companion/`
- **Тема**: Системная/Светлая/Тёмная через настройки
- **Язык**: Автоопределение или ручной выбор

### Лицензия

MIT License - см. файл LICENSE.

---

<div align="center">

**Made with ❤️ using Python + Flet**

</div>
# sanchoAI
