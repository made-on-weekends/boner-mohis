# API.md

> Backend API contract for DESCO live integration.

## Conventions

- Base URL: `https://prepaid.desco.org.bd`
- Auth: None (parameters validated using client `accountNo` and `meterNo` query keys)
- Content-Type: `application/json`

## Endpoints

### 1. Customer Balance

Retrieves the current prepaid balance and billed consumption cost for the month.

#### `GET /api/tkdes/customer/getBalance`

- **Query Parameters**:
  - `accountNo` (string, required `[PII]`) — Customer account number.
  - `meterNo` (string, required `[PII]`) — Meter serial number.

- **Response 200 (Success)**:
  ```json
  {
    "code": 200,
    "desc": "Success",
    "data": {
      "accountNo": "22056161",
      "meterNo": "12003456",
      "balance": "1399.15",
      "currentMonthConsumption": "811.25"
    }
  }
  ```
  *(Note: `currentMonthConsumption` represents the BDT currency cost spent in the billing cycle, NOT the kWh usage.)*

### 2. Daily Consumption History

Retrieves historical cumulative meter and cost telemetry for a specified date range.

#### `GET /api/tkdes/customer/getCustomerDailyConsumption`

- **Query Parameters**:
  - `accountNo` (string, required `[PII]`)
  - `meterNo` (string, required `[PII]`)
  - `dateFrom` (string, required, `YYYY-MM-DD`)
  - `dateTo` (string, required, `YYYY-MM-DD`)

- **Response 200 (Success)**:
  ```json
  {
    "code": 200,
    "desc": "Success",
    "data": [
      {
        "date": "2026-07-01",
        "consumedUnit": "22583.369",
        "consumedTaka": "121.39"
      },
      {
        "date": "2026-07-02",
        "consumedUnit": "22609.583",
        "consumedTaka": "272.36"
      }
    ]
  }
  ```
  *(Note: `consumedUnit` is the cumulative all-time meter odometer reading in kWh, which never resets. `consumedTaka` is the cumulative BDT cost billed since the start of the billing month, resetting to 0 on billing rollover.)*
