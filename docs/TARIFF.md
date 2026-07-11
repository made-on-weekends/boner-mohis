# Tariff Structure

## Overview

Boner Mohis uses the **Bangladesh Power Development Board (BPDB) Category-A Residential** progressive tariff schedule. The same 7-slab rate table applies across all currently supported distributors (DESCO, DPDC, default). All rates are in **Bangladeshi Taka (৳) per kWh**.

> **Do not change slab rates or boundaries in code without updating this document and citing the official BPDB/BERC gazette notification.**

---

## Category-A Residential Slab Table

| # | Tier Name    | Usage Range (kWh/month) | Rate (৳/kWh) |
|---|--------------|-------------------------|---------------|
| 0 | Lifeline     | 0 – 50                  | 4.63          |
| 1 | First Step   | 0 – 75                  | 5.26          |
| 2 | Second Step  | 76 – 200                | 8.50          |
| 3 | Third Step   | 201 – 300               | 9.10          |
| 4 | Fourth Step  | 301 – 400               | 9.62          |
| 5 | Fifth Step   | 401 – 600               | 15.01         |
| 6 | Sixth Step   | Above 600               | 17.35         |

> **Lifeline bypass rule**: The Lifeline slab (0–50 kWh @ ৳4.63) applies **only** when total monthly usage is **≤ 50 kWh**. If usage exceeds 50 kWh the entire 0–75 kWh range is billed at the First Step rate (৳5.26). The Lifeline slab is skipped in that case.

> **Progressive billing**: each slab rate applies only to the units consumed *within* that slab’s range. The total bill is the sum across all slabs consumed.

---

## Calculation Logic

### Bill Calculation (`calculateCost`)

Iterates through slabs in order, billing each consumed unit at the rate of the slab it falls in.
**Lifeline bypass**: if `total_kwh > 50`, skip slab 0 (Lifeline) entirely and start from slab 1 (First Step, 0–75 kWh @ ৳5.26):

```
remaining = total_kwh
cost = 0

if total_kwh <= 50:
    start from slab 0 (Lifeline)
else:
    start from slab 1 (First Step)

for each slab from start_slab (limit, rate):
    consumed_in_slab = min(remaining, slab.limit - prev_limit)
    cost += consumed_in_slab × rate
    remaining -= consumed_in_slab
    prev_limit = slab.limit
    if remaining == 0: break
```

**Example** — 124.01 kWh (> 50, so Lifeline skipped, First Step starts at 0):
- First Step (0–75): 75 × 5.26 = **394.50 ৳**
- Second Step (75–124.01): 49.01 × 8.50 = **416.59 ৳**
- **Total ≈ 811.09 ৳** (before VAT/surcharge)

**Example** — 40 kWh (≤ 50, so Lifeline applies):
- Lifeline (0–40): 40 × 4.63 = **185.20 ৳**

### Active Slab Detection (`getSlabDetails`)

Returns which slab the current usage falls into, plus:
- `slabMin` / `slabMax` — the boundary of the active tier (used for the UI progress bar)
- `percentage` — how far through the current tier the usage is (0–100 %)
- `label` — human-readable tier name with range

---

## Distributor Mapping

All three current distributor keys share the same slab configuration:

| Key       | Name                    |
|-----------|-------------------------|
| `desco`   | DESCO (Dhaka Electric)  |
| `dpdc`    | DPDC (Dhaka Power)      |
| `default` | Standard Progressive    |

If a future distributor uses a different rate schedule, add a new key to `DISTRIBUTORS` in both:
- [`CalculationsHelper.kt`](../android/app/src/main/java/com/example/bonermohis/data/CalculationsHelper.kt)
- [`calculations.js`](../extension-react/src/calculations.js)

---

## API Data Notes (DESCO)

| API Field                  | Type | Meaning              |
|----------------------------|------|----------------------|
| `balance`                  | BDT  | Remaining prepaid balance |
| `currentMonthConsumption`  | BDT  | **Cost** billed this month (NOT kWh — do not use as kWh) |
| `consumedUnit`             | kWh  | **Cumulative all-time meter reading** — never resets |
| `consumedTaka`             | BDT  | Cumulative cost — **resets to 0 at month boundary** |

### Correct monthly kWh derivation

`consumedUnit` is an all-time odometer — it never resets. `consumedTaka` resets at the billing month boundary.

**Wrong** (off-by-one day, misses ~26 kWh):
```
monthlyKwh = latestEntry.consumedUnit - firstEntryOfCurrentMonth.consumedUnit
```
This skips the first day of the month's own consumption (e.g. Jul 01 = 26.21 kWh uncounted → gives 97.8 instead of 124 kWh).

**Correct** — use the **last entry of the previous month** as the base:
```
base = lastEntryOfPreviousMonth.consumedUnit   // e.g. Jun 30 = 22583.369
monthlyKwh = latestEntry.consumedUnit - base   // 22707.39 - 22583.369 = 124.021 kWh ✓
```

Fallback (if all entries are within the current month — e.g. on the 1st with only 1 day of history): use the first entry of the current month as the base.

