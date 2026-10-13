# SECURITY.md

> Technical security architecture, threat model, and engineering hard rules. Cross-references `DATABASE.md` and `API.md`. For public vulnerability disclosure and supported versions, see [SECURITY.md](../SECURITY.md).

## Hard Rules

These rules are **absolute**. Violating any of them requires an explicit entry in `docs/DECISIONS.md`.

1. **Never** disable TLS verification or use `badCertificateCallback = (cert, host, port) => true`.
2. **Never** send account numbers, meter numbers, or usage records to any server other than official DESCO endpoints (`prepaid.desco.org.bd`).
3. **Never** integrate third-party analytics, tracking SDKs, or crash telemetry that transmits consumer usage data.
4. **Never** log account credentials, balance figures, or customer tokens in production logs.
5. **Always** use parameterized SQL queries through `sqflite` to prevent SQL injection.
6. **Always** validate account number and meter number formats before dispatching network requests.
7. **Never** store financial data, payment card info, or banking credentials.

## TLS Certificate Architecture

### DigiCert Global G2 Intermediate CA Pinning

The DESCO customer API server fails standard Android TLS validation because it transmits an incomplete certificate chain (omits intermediate CAs).

- **Implementation**: `lib/data/desco_http_client.dart` loads the root/intermediate bundle from `assets/certs/digicert_global_g2.pem` and injects it into a dedicated `SecurityContext`.
- **Scope**: Trust is strictly scoped to `IOClient` instances created for DESCO communication. It does not tamper with the platform's root trust store or global VM socket settings.

## Data Storage & Local Privacy

- **Account Credentials**: `accountNo` and `meterNo` are public identifiers on the physical meter box. They are stored locally on-device in `boner_mohis.db` (Android) and `chrome.storage.local` (Chrome extension).
- **Encryption at Rest**: Relies on Android system-level sandboxing (UID file separation) and Chrome extension local storage segregation.
- **Zero Cloud Transmission**: The application has no proprietary backend server, sync proxy, or centralized database.

## Threat Model — Top Concerns

1. **Man-In-The-Middle (MitM) on Untrusted Wi-Fi**:
   - *Threat*: Interception or modification of balance responses.
   - *Mitigation*: HTTPS enforcement with DigiCert intermediate CA verification ensures communication connects strictly to authenticated DESCO servers.
2. **SQL Injection via User Input**:
   - *Threat*: Malicious nickname or account numbers attempting SQL injection.
   - *Mitigation*: All DAO operations utilize parameterized SQL queries (`?` bindings) in `sqflite`.
3. **Information Disclosure on Shared Devices**:
   - *Threat*: Unauthorized local viewing of electricity usage patterns.
   - *Mitigation*: Data is stored within the app-private data directory, inaccessible to other Android apps without root permissions.

## Incident Response

If a vulnerability or certificate issue is identified:
1. **Assess**: Determine if certificate pinning is affected or if an API change has occurred.
2. **Patch**: Update the local certificate asset or validation rules.
3. **Release**: Deploy updated build to GitHub Releases and App stores.
4. **Disclose**: Document fix in `CHANGELOG.md` per responsible disclosure guidelines in root `SECURITY.md`.
