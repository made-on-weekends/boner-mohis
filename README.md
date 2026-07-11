# Boner Mohis — Prepaid Electricity Balance & Usage Tracker

A privacy-first, 100% local utility to track prepaid electricity account balances, monitor progressive billing slabs, and forecast depletion timelines based on recent daily consumption.

---

## ⚡ Deliverables

1. **Chrome Extension (React + Vite)** — Runs locally in your browser. Opens in the extension popup. Features interactive simulator controls to test progressive slabs, top-ups, and balance forecasts.
2. **Android Companion App (Compose + Room)** — Local SQLite database, Jetpack Compose dashboard UI, and a background `WorkManager` scheduler that triggers low-balance checks and push alerts.

---

## 🚀 Quickstart

### 1. Chrome Extension Setup

#### Development & Compilation
1. Navigate to the React source folder:
   ```bash
   cd extension-react
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Build the unpacked extension directory:
   ```bash
   npm run build
   ```
   *This compiles the React files and outputs the unpacked extension directly into the `/extension` directory.*

#### Loading into Google Chrome
1. Open Google Chrome and navigate to `chrome://extensions/`.
2. Enable **Developer mode** (toggle in the top-right corner).
3. Click **Load unpacked** (top-left).
4. Select the `/extension` directory in the root of this repository.
5. Pin the extension.

### 2. Android App Setup

1. Open the `/android` directory in **Android Studio**.
2. Verify that Gradle uses **JDK 17** (configured locally in `gradle.properties` via `org.gradle.java.home`).
3. Build and deploy the application to an emulator or physical device.

---

## 🛠 Tech Stack

- **Chrome Extension:** React 19, Vite 8, ES6+ JS, Local Storage (`chrome.storage.local`).
- **Android Companion:** Kotlin, Jetpack Compose, SQLite via Room Database, background worker execution via WorkManager.

---

## 📂 Repository Structure

```
/
├── extension/          # Unpacked Chrome Extension build output (Vite dist)
├── extension-react/    # Chrome Extension React/Vite source code
├── android/            # Android Studio Kotlin/Room project files
├── docs/               # Canonical specifications and design files
├── README.md           # Human developer quickstart guide (this file)
└── AGENTS.md           # AI coding agent briefing packet
```

---

## 📖 Project Documentation

For complete design and developer specifications, see:
- [docs/PRODUCT.md](docs/PRODUCT.md) — Scope limits, personas, and success criteria.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Architectural layers, calculation formulas, and lifecycles.
- [docs/DESIGN.md](docs/DESIGN.md) — Visual style system tokens and outline layouts.
- [docs/BRAND.md](docs/BRAND.md) — Positioning, voice guidelines, and naming conventions.
- [docs/UX.md](docs/UX.md) — Navigation flows, alert triggers, and simulation behaviors.
- [docs/COMPONENTS.md](docs/COMPONENTS.md) — Composite UI components specifications (ChargeBar, etc.).
- [docs/TESTING.md](docs/TESTING.md) — Test strategies and commands.
- [docs/DATABASE.md](docs/DATABASE.md) — Storage strategies (`chrome.storage` & Room SQLite).
- [docs/SCHEMA.md](docs/SCHEMA.md) — Data schemas for accounts, logs, and billing cycles.
- [docs/SECURITY.md](docs/SECURITY.md) — Input sanitization, CSP rules, and PII storage boundaries.
- [docs/API.md](docs/API.md) — Live DESCO API integration contract.
- [docs/TARIFF.md](docs/TARIFF.md) — Progressive billing slab tariff configuration.


## 🐛 Issues & Troubleshooting

Encountered an issue or have a feature suggestion?
- View our [Quick Guide to Reporting Issues](REPORTING.md) before submitting an issue.
- Read [AGENTS.md](AGENTS.md) for quick command reminders and agent coding guidelines.

## 🤝 Contributing

We are always looking for improvements and additions! Please read the [Contribution Guide](CONTRIBUTING.md) to understand our branching strategy, conventions, and pull request checklist.

## ⭐ Support Us

If **Boner Mohis** makes tracking prepaid electricity balances and usage forecasts seamless:
- ⭐ **Star this repository** to help others discover the project.
- 📣 **Spread the word** on X/Twitter or your blog.
- ☕ **Support the maintainer** via [donation](https://asifiqbal.rocks/donation) to fund further open-source initiatives.

---

## 📄 License

This project is licensed under the [MIT License](https://choosealicense.com/licenses/mit).
