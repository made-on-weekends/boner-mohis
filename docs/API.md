# API.md

> External DESCO API contract and network integration specifications.

## Overview

Boner Mohis interfaces directly with the public DESCO Prepaid Customer portal web service (`prepaid.desco.org.bd`). The app communicates read-only with these endpoints to query meter state.

## Conventions

- **Base URL**: `https://prepaid.desco.org.bd/api/tkdes/customer`
- **Protocol**: HTTPS (TLS 1.2 / 1.3)
- **Authentication**: Public query parameters based on consumer `accountNo` and `meterNo`. No API token or session header required.
- **Content-Type**: `application/json`
- **TLS Pinning**: Scoped `SecurityContext` containing DigiCert Global G2 Intermediate CA certificate (`assets/certs/digicert_global_g2.pem`).

## TLS Intermediate Pinning Rationale

The DESCO server infrastructure serves only its leaf TLS certificate, omitting the intermediate DigiCert Global G2 CA certificate. Standard Android devices fail the TLS handshake with `CERTIFICATE_VERIFY_FAILED`. To resolve this safely without disabling TLS verification:
- The app bundles `digicert_global_g2.pem`.
- `createDescoHttpClient()` binds this certificate to an isolated `SecurityContext`.

## Endpoints

### 1. Get Live Balance

Retrieves current balance and total consumed units for the meter.

#### `GET /getBalance`

**Query Parameters:**
- `accountNo` (string, required): 8-digit DESCO consumer account number.
- `meterNo` (string, required): 11-digit or 12-digit physical meter number.

**Response 200 (Success):**
```json
{
  "code": 200,
  "desc": "success",
  "data": {
    "balance": 524.38,
    "readingTime": "2026-10-13 18:30:00",
    "meterStatus": "Normal",
    "currentMonthUnit": 142.50
  }
}
```

**Response (Error / Invalid Meter):**
```json
{
  "code": 400,
  "desc": "Account or meter number not found",
  "data": null
}
```

---

### 2. Get Daily Consumption History

Retrieves historical daily consumption records for a specified date window (up to 35 days).

#### `GET /getCustomerDailyConsumption`

**Query Parameters:**
- `accountNo` (string, required): DESCO account number.
- `meterNo` (string, required): Meter number.
- `dateFrom` (string, required): Start date in `yyyy-MM-dd` format.
- `dateTo` (string, required): End date in `yyyy-MM-dd` format.

**Response 200 (Success):**
```json
{
  "code": 200,
  "desc": "success",
  "data": [
    {
      "date": "2026-10-11",
      "consumedUnit": 138.2,
      "cost": 34.50
    },
    {
      "date": "2026-10-12",
      "consumedUnit": 142.5,
      "cost": 36.12
    }
  ]
}
```

## Error Handling & Fallback Policy

1. **Network Timeout**: Network calls are subject to a 10-second timeout.
2. **Server Unavailability**: When DESCO endpoints return 5xx errors or connection times out, the application falls back to locally stored SQLite records with an indicator showing the last successful sync timestamp.
3. **Invalid Credentials**: If DESCO returns an error description, it is returned directly to the UI without wiping existing cached records.
