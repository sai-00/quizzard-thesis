# Quizzard
Thesis project

## PREREQUISITES
- Flutter SDK
  (https://docs.flutter.dev/install)
- Android Studio (Recommended)
  Includes Android SDK and emulator support.
  (https://developer.android.com/studio/install)
- When using Windows : Turn Developer Mode on in settings.
> Note : Other IDEs/editors can work as long as Flutter and Android SDK are properly installed

## SETUP
> Using VS Code
1. Clone the repository 
   In a terminal: Run `git clone https://github.com/sai-00/quizzard-thesis.git`
2. Open project, navigate to root folder.
3. Open a terminal in the root folder (on VS Code: `ctrl + J`).
4. Run `flutter pub get` to install dependencies.
5. Run `flutter run` and select "1" to run the application.

## IMPORTANT !!!
- lib/screens => UI and logic only, no DB calls here.
- lib/repositories => all DB logic (CRUD). Use these inside screens.
- lib/models => pure data classes.
- lib/services => helper classes (CSV, sprite manager, etc).
- lib/db => central database setup (DO NOT edit except for schema changes).

