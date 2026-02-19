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
- 🌐 **Vision Models** - Support for multimodal models (Gemma 3 Vision)
- 📝 **Markdown Support** - Rich text formatting in responses
- 🔄 **Continue Generation** - Continue AI responses with one click
- 📊 **Status Indicator** - Visual feedback for model state (loading/ready/generating/error)
- 🌙 **Theme Support** - Light, Dark, and System theme modes
- 🌍 **Multilingual** - Russian and English interface
- 💾 **History** - Persistent chat history with SQLite
- ⚙️ **Customizable** - Configure AI personality via system prompt
- 📤 **Export** - Export conversations to JSON

### Requirements

- Python 3.10+
- 4GB+ RAM (6GB+ recommended)
- Android 8.0+ (for APK)
- GGUF model file + mmproj file (for vision models)

### Models

The app uses Gemma 3 4B Vision model:
- `gemma-3-4b-it-Q3_K_M.gguf` - Main model
- `mmproj-model-f16.gguf` - Vision projector

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
│   │   ├── message_bubble.py  # Chat messages with Markdown
│   │   └── status_bar.py      # Model status indicator
│   ├── models/            # Data models
│   ├── i18n/              # Internationalization
│   └── utils/             # Utilities
├── gemma-3-4b-it-Q3_K_M.gguf  # AI Model (Vision)
├── mmproj-model-f16.gguf      # Vision projector
├── requirements.txt
└── main.py
```

### Configuration

- **AI Model**: Gemma 3 4B Vision GGUF model
- **Context Window**: 4096 tokens
- **Database**: SQLite stored in `~/.ai_companion/`
- **Theme**: System/Light/Dark via settings
- **Language**: Auto-detected or manual in settings

### Status Indicators

- ⏳ **Idle** - Waiting for user input
- 📥 **Loading** - Model is loading
- ✅ **Ready** - Model ready for inference
- 🤖 **Generating** - AI is generating response
- ❌ **Error** - Error loading model

### License

MIT License - See LICENSE file for details.

---

<a name="русский"></a>

## Русский

### Функции

- 💬 **Чат с AI** - Разговорный AI на основе локальной GGUF модели
- 🌐 **Vision модели** - Поддержка мультимодальных моделей (Gemma 3 Vision)
- 📝 **Поддержка Markdown** - Форматирование текста в ответах
- 🔄 **Продолжить генерацию** - Продолжить ответ AI одним кликом
- 📊 **Индикатор статуса** - Визуальная обратная связь о состоянии модели
- 🌙 **Темы** - Светлая, тёмная и системная темы
- 🌍 **Многоязычность** - Русский и английский интерфейс
- 💾 **История** - Сохранение истории чата в SQLite
- ⚙️ **Настройка** - Изменение личности AI через system prompt
- 📤 **Экспорт** - Экспорт диалогов в JSON

### Требования

- Python 3.10+
- 4GB+ RAM (рекомендуется 6GB+)
- Android 8.0+ (для APK)
- GGUF файл модели + mmproj файл (для vision моделей)

### Модели

Приложение использует модель Gemma 3 4B Vision:
- `gemma-3-4b-it-Q3_K_M.gguf` - Основная модель
- `mmproj-model-f16.gguf` - Проектор для vision

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
│   │   ├── message_bubble.py  # Сообщения с Markdown
│   │   └── status_bar.py      # Индикатор статуса модели
│   ├── models/             # Модели данных
│   ├── i18n/              # Переводы
│   └── utils/             # Утилиты
├── gemma-3-4b-it-Q3_K_M.gguf  # AI модель (Vision)
├── mmproj-model-f16.gguf      # Vision проектор
├── requirements.txt
└── main.py
```

### Настройка

- **AI Модель**: Gemma 3 4B Vision GGUF
- **Контекстное окно**: 4096 токенов
- **База данных**: SQLite в `~/.ai_companion/`
- **Тема**: Системная/Светлая/Тёмная через настройки
- **Язык**: Автоопределение или ручной выбор

### Индикаторы статуса

- ⏳ **Ожидание** - Ожидание ввода пользователя
- 📥 **Загрузка** - Модель загружается
- ✅ **Готов** - Модель готова к работе
- 🤖 **Генерация** - AI генерирует ответ
- ❌ **Ошибка** - Ошибка загрузки модели

### Лицензия

MIT License - см. файл LICENSE.

---

<div align="center">

**Made with ❤️ using Python + Flet**

</div>
