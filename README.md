# Sancho.AI

A local AI chatbot application for Android built with Flutter. Runs GGUF-compatible AI models directly on your device.

## Features

- **Local AI Model Execution** - Run GGUF-compatible language models (Llama, Mistral, Qwen, etc.) directly on Android
- **Chat Interface** - Clean and intuitive chat UI with markdown support
- **Model Management** - Easy model selection and loading from device storage
- **Customizable Settings** - System prompt configuration, theme selection (light/dark/system)
- **Conversation History** - Automatic saving and loading of chat conversations
- **Real-time Status** - Visual indicator showing model loading and generation status

## Requirements

- Android device with Android 8.0 (API 26) or higher
- GGUF format AI model file (.gguf)

## Installation

1. Download the latest APK from the Releases section
2. Install the APK on your Android device
3. Go to Settings and select your AI model file
4. Wait for the model to load
5. Start chatting!

## Model Setup

1. Download a GGUF-compatible model (e.g., from Hugging Face)
2. Transfer the model file to your Android device
3. Open the app → Settings → Select Model
4. Choose your model file and wait for loading to complete

Recommended models:
- Qwen2.5-0.5B-Instruct-Q4_K_M.gguf
- llama-3.2-1b-instruct-q4_k_m.gguf
- mistral-7b-instruct-v0.2-q4_k_m.gguf

## Technical Details

- **Framework**: Flutter
- **State Management**: Riverpod
- **Model Runtime**: llama.cpp via llama_flutter_android
- **Storage**: SharedPreferences for settings and conversation history
- **Architecture**: Clean Architecture (Presentation / Domain / Data layers)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/Qkartq/SanchoAI.git

# Navigate to project directory
cd SanchoAI/sanchoai

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## Screenshots

| Chat Screen | Settings |
|-------------|----------|
| Modern chat interface with status indicator | Model selection and configuration |

## License

MIT License

## Author

Qkartq
