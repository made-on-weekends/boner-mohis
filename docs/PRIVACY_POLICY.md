# Privacy Policy for Boner Mohis

**Effective Date:** July 11, 2026

At **Boner Mohis** ("we", "our", or "us"), we are committed to protecting your privacy. This Privacy Policy explains how our Chrome Extension and Android Companion App collect, use, and protect your information.

## 1. 100% Local Execution (No Data Collection)
Boner Mohis is designed from the ground up as a **privacy-first, client-only application**. 
* **No External Servers:** We do not host any remote databases, analytics servers, or tracking endpoints.
* **No Data Harvesting:** We do not collect, upload, share, or transmit your utility account numbers, meter numbers, balances, usage logs, or IP addresses to any third parties.

## 2. Information We Store Locally
To provide dashboard visualizations, progressive slab tracking, and low-balance forecasts, the application stores the following information locally on your device:
* **Account Configuration:** Nickname, utility provider name, utility account number, and meter serial number.
* **Usage Records:** Daily consumption values, yesterday's balance, and slab limits/rates.

### Storage Mechanisms
* **Chrome Extension:** Handled inside your browser using the local storage API (`chrome.storage.local`).
* **Android Companion App:** Handled inside a local SQLite database on your device using Android Room.

## 3. Network Permissions
The application utilizes network permissions for the sole purpose of fetching utility account balances directly from your provider:
* **Host Permission (`https://prepaid.desco.org.bd/*`):** Used strictly within your browser (Chrome Extension) to retrieve the latest meter reading and balance from the official DESCO portal. No intermediary servers are involved in this transaction.

## 4. User Control and Data Deletion
Since all data is stored entirely on your local device, you have complete control over it:
* **Deleting Storage:** You can remove all stored accounts and logs by clearing the application storage in your browser settings (for the Chrome Extension) or device application settings (for the Android app).
* **Uninstalling:** Uninstalling the Chrome Extension or Android Companion App will immediately and permanently delete all local databases and stored information.

## 5. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. Any changes will be reflected by updating this document within our official source repository.

## 6. Contact Us
If you have any questions or feedback regarding our privacy practices, feel free to open an issue in our official repository.
