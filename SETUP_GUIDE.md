# Smriti Setup & Build Guide

Smriti is an advanced AI Notebook (Obsidian + Notion + NotebookLLM) that runs 100% locally on your phone or connects to cloud APIs using your own keys.

## 🚀 Prerequisites

- Flutter SDK (>= 3.10)
- Android Studio / Xcode
- For Local AI: High-RAM device (6GB+ recommended for Gemma 2B, 4GB+ for Llama 3.2 1B)

## 🛠️ Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd smriti
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate database files**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📦 Building for Production

### Android (APK & AAB)
```bash
# Generate Release APK
flutter build apk --release

# Generate Android App Bundle (AAB) for Play Store
flutter build appbundle --release
```
The files will be located in `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/`.

### iOS
```bash
flutter build ios --release
```
Then open `ios/Runner.xcworkspace` in Xcode to archive and upload to App Store.

## 🤖 AI Model Selection Guide

Based on your device RAM:
- **Low RAM (4GB)**: Use **Llama 3.2 1B (Q4)**. It's fast and fits in memory.
- **Mid RAM (6GB)**: Use **Gemma 2B (Q4)**. Best balance of accuracy and speed.
- **High RAM (8GB+)**: Use **Phi-3 Mini (Q4)** for superior reasoning.
- **Cloud Mode**: Use **GPT-4o mini** or **Claude 3.5 Sonnet** if you have API keys and internet.

## 📤 Sending to GitHub (New Project)

If you are not in a git repo:
```bash
git init
git add .
git commit -m "Initial commit: Smriti Advanced AI Notebook"
git remote add origin <your-empty-repo-url>
git push -u origin main
```

To send a Pull Request to another empty project:
1. Fork the empty project on GitHub.
2. Add it as a remote: `git remote add upstream <empty-project-url>`
3. Push your branch: `git push origin main`
4. Go to GitHub and click "New Pull Request".
