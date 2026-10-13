# Security Policy

We take the security of this project seriously. This document outlines our policy for reporting security vulnerabilities and supported versions.

For detailed internal security architecture, threat models, and engineering rules, refer to [docs/SECURITY.md](docs/SECURITY.md).

---

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## Reporting a Vulnerability

> [!CAUTION]
> Please do NOT report security vulnerabilities through public GitHub issues, discussions, or pull requests.

If you believe you have discovered a security vulnerability in this project, please report it responsibly:

1. **Email / Contact:** Send a report directly to security@madeonweekends.com.
2. **Details to Include:**
   - Type of issue (e.g. certificate validation bypass, insecure local storage, injection).
   - Full paths of source file(s) related to the manifestation of the issue.
   - The location of the affected source code (tag/branch/commit or direct URL).
   - Any special configuration required to reproduce the issue.
   - Step-by-step instructions to reproduce the issue.
   - Proof-of-concept or exploit code (if possible).
   - Impact of the issue, including how an attacker might exploit the issue.

### Response & Disclosure Process

- **Acknowledgment:** We will acknowledge receipt of your vulnerability report within 48 hours.
- **Assessment:** We will confirm the vulnerability, assess its severity, and keep you informed of our progress.
- **Fix & Disclosure:** Once a fix is verified, a patch will be released and credit will be given to the reporter in our release notes (unless requested otherwise).

Thank you for helping keep our project and users safe!
