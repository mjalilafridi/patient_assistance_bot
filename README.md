# Patient Chat Bot

A cross-platform Flutter application that acts as a patient assistant chatbot. The bot collects basic user information and provides personalized health advice using the Gemini API.

## Features

- Conversational chatbot interface
- Integrates with Gemini API for health-related advice
- Personalized responses based on user profile
- Clean, modern UI built with Flutter


## Getting Started

These instructions will help you set up and run the project on your local machine.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.8.1 or higher recommended)
- Dart SDK (comes with Flutter)
- An editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
- For mobile: Android/iOS emulator or device
- For web: Chrome or compatible browser

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/mjalilafridi/patient_assistance_bot.git
   cd patient_assistance_bot
   ```

2. **Install dependencies:**

   ```sh
   flutter pub get
   ```

3. **(Optional) Update dependencies:**

   ```sh
   flutter pub upgrade
   ```

### Running the App

You can run the app on Android, iOS, web, Windows, macOS, or Linux.

#### For Android/iOS

1. **Start an emulator** or connect a device.
2. **Run:**

   ```sh
   flutter run
   ```

#### For Web

```sh
flutter run -d chrome
```

#### For Desktop (Windows, macOS, Linux)

```sh
flutter run -d windows 
```

### Project Structure

- `lib/main.dart` - App entry point
- `lib/screens/chat_screen.dart` - Main chat interface and logic
- `pubspec.yaml` - Project dependencies and configuration

### Dependencies

- `flutter`
- `http` - For API requests
- `flutter_markdown` - For rendering bot messages

### API Key

This project uses the Gemini API. You must provide your own API key in `lib/screens/chat_screen.dart`:

```dart
final String apiKey = 'YOUR_API_KEY_HERE';
```

Replace `'YOUR_API_KEY_HERE'` with your actual Gemini API key.