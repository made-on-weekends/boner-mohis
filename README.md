# Boner Mohis (বনের মহিষ)

> Prepaid electricity balance and consumption tracker for DESCO consumers in Bangladesh.

Boner Mohis provides transparent, real-time insight into prepaid electricity meter balances, daily consumption, slab transitions, and emergency balance warnings without requiring third-party cloud servers or exposing account credentials. Built as an Android mobile app in Flutter and a companion Chrome extension in React.

---

## 🚀 Quickstart

### Android Mobile App (Flutter)

```bash
# Clone the repository
git clone https://github.com/made-on-weekends/boner-mohis.git
cd boner-mohis

# Fetch dependencies and verify environment
flutter pub get
flutter analyze
flutter test

# Run the application
flutter run
```

### Chrome Extension (`extension-react/`)

```bash
cd extension-react

# Install dependencies and build extension
npm ci
npm run lint
npm run build

# Load into Chrome:
# 1. Open chrome://extensions/
# 2. Enable "Developer mode"
# 3. Click "Load unpacked" and select the generated 'extension/' folder at repo root
```

---

## 🛠️ Stack

- **Mobile Client**: Flutter 3.x (Dart ^3.12.2, Android)
- **Browser Extension**: React 19, Vite 8, Oxlint
- **Local Database**: SQLite via `sqflite`
- **State Management**: `flutter_riverpod`
- **Background Sync**: `workmanager` & `flutter_local_notifications`
- **Network & TLS**: HTTP with DigiCert Global G2 CA certificate pinning
- **Typography & Theme**: Space Grotesk, DM Sans, DM Mono via Filament Design System

---

## 📂 Project Structure

```
.
├── android/          # Android platform wrapper and native manifests
├── assets/           # Root public assets (TLS certificates)
├── extension-react/  # React 19 + Vite Chrome extension source
├── lib/              # Flutter mobile application source code
│   ├── background/   # Workmanager sync and local notification dispatch
│   ├── data/         # SQLite database, DAOs, DESCO client, calculations
│   ├── providers/    # Riverpod state notifiers and providers
│   └── ui/           # Screens, widgets, and Filament theme
├── test/             # Flutter unit and widget tests
└── docs/             # Canonical project documentation
```

---

## 📚 Documentation

For technical details, project guidelines, and development context:

- 🤖 **For AI Coding Agents:** Refer to [AGENTS.md](AGENTS.md) for development commands, project conventions, and agent instructions.
- 🏗️ **Architecture:** See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the system structure, major components, and data flows.
- 🎯 **Product Scope:** See [docs/PRODUCT.md](docs/PRODUCT.md) for product goals, supported features, and planned work.
- 🎨 **Design System:** See [docs/DESIGN.md](docs/DESIGN.md) for color tokens, typography, and component specifications.
- 🏷️ **Brand Guidelines:** See [docs/BRAND.md](docs/BRAND.md) for identity rules, bilingual leading, and emblem states.
- 🔌 **API Contract:** See [docs/API.md](docs/API.md) for DESCO prepaid customer API endpoints and response formats.
- 🗄️ **Database & Schema:** See [docs/DATABASE.md](docs/DATABASE.md) and [docs/SCHEMA.md](docs/SCHEMA.md) for SQLite tables and DAOs.
- 🛡️ **Security Guidelines:** See [SECURITY.md](SECURITY.md) and [docs/SECURITY.md](docs/SECURITY.md) for certificate pinning and local storage rules.
- 🧪 **Testing Strategy:** See [docs/TESTING.md](docs/TESTING.md) for test suites, coverage, and verification procedures.
- 📱 **Android Device & APK Testing:** See [docs/ANDROID_DEVICE_TESTING.md](docs/ANDROID_DEVICE_TESTING.md) for APK installation, device testing, and WorkManager background job verification.
- ⚖️ **Decision Log:** See [docs/DECISIONS.md](docs/DECISIONS.md) for architectural decisions, rationale, and established conventions.


---

## 🐛 Issues & Troubleshooting

Found a bug or have a feature request?

- Read the [Issue Reporting Guide](REPORTING.md) before submitting an issue.
- Please report bugs or request features via the [GitHub Issues](https://github.com/made-on-weekends/boner-mohis/issues) tracker.

---

## 🤝 Contributing

Contributions are welcome! Read the [Contribution Guide](CONTRIBUTING.md) for development setup, contribution conventions, and the pull request process.

---

## ⭐ Support Us

If Boner Mohis is useful to you:

- ⭐ **Star this repository** to help others discover the project.
- 📣 **Spread the word** by sharing it with your network.
- ☕ **Support Our Work** — [Donate](https://asifiqbal.rocks/donation?utm_source=boner_mohis&utm_medium=github_readme&utm_campaign=readme&ref=boner-mohis-readme) to help us maintain and grow our open-source projects.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
