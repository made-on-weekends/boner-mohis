import { getSlabDetails, DISTRIBUTORS } from './calculations.js';
import { db } from './storage.js';

/**
 * Fetches a URL, routing through the background service worker when inside the
 * extension so the SW's unconditional host_permissions bypass avoids CORS walls.
 * Falls back to plain fetch() in the dev-server preview context.
 * @param {string} url
 * @returns {Promise<{ ok: boolean, status: number, data: any }>}
 */
async function extensionFetch(url) {
  const isExtension = typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.id;
  if (isExtension) {
    return new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({ type: 'FETCH', url }, (response) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
        } else if (!response) {
          reject(new Error('No response from background service worker'));
        } else if (!response.ok) {
          reject(new Error(response.error || `HTTP ${response.status}`));
        } else {
          resolve(response);
        }
      });
    });
  }
  // Dev-server / non-extension fallback
  const res = await fetch(url);
  const data = await res.json();
  return { ok: res.ok, status: res.status, data };
}

/**
 * Adapter pattern interface for electricity providers.
 */
export const providers = {
  /**
   * Syncs account details with the live distributor API (DESCO)
   * @param {string} accountId 
   * @returns {Promise<object>} The updated account object
   */
  syncAccount: async (accountId) => {
    const accounts = await db.getAccounts();
    const account = accounts.find(a => a.id === accountId);
    if (!account) throw new Error("Account not found");

    if (account.distributor !== 'desco') {
      return account; // Only DESCO has API integration verified via HAR
    }

    const isExtension = typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.id;

    if (!isExtension) {
      console.log("Running in browser preview mode. Simulating DESCO API response.");
      
      const isTestAccount = account.accountNo === '22056161';
      // Values sourced directly from HAR capture (2026-07-06):
      //   getBalance: balance=1399.15 BDT, currentMonthConsumption=811.25 BDT (NOT kWh!)
      //   getCustomerDailyConsumption: latest consumedUnit=124.01 kWh (this is the kWh total)
      //   yesterday delta: last.consumedTaka - secLast.consumedTaka = 223.04 BDT
      const liveBalance    = isTestAccount ? 1399.15 : (account.balance     || 1250.00);
      const liveMonthlyKwh = isTestAccount ? 124.01  : (account.monthlyKwh  || 85.40);
      const yesterdayCost  = isTestAccount ? 223.04  : (account.yesterdayUsage || 28.50);

      for (let i = 0; i < 30; i++) {
        const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const dateStr = d.toISOString().split('T')[0];
        const baseKwh = isTestAccount ? 25.0 : 5.0;
        const baseCost = isTestAccount ? 180.0 : 27.5;
        const kwhVar = Math.sin(i * 0.7) * 2.5 + (i % 3 === 0 ? 3.0 : 0);
        const kwh = Number(Math.max(3.5, baseKwh + kwhVar).toFixed(1));
        const cost = Number((kwh * (baseCost / baseKwh)).toFixed(2));
        await db.addHistoryRecord(accountId, dateStr, kwh, cost);
      }

      const slabStats = getSlabDetails(liveMonthlyKwh, 'desco');
      const updatedAccount = {
        ...account,
        balance: liveBalance,
        monthlyKwh: liveMonthlyKwh,
        yesterdayUsage: yesterdayCost,
        currentSlab: slabStats.index,
        slabUsage: Number((liveMonthlyKwh - slabStats.slabMin).toFixed(2)),
        lastUpdated: new Date().toISOString()
      };

      await db.saveAccount(updatedAccount);
      return updatedAccount;
    }

    try {
      // 1. Fetch balance — routed through SW to avoid CORS issues from extension tabs
      const balResult = await extensionFetch(
        `https://prepaid.desco.org.bd/api/tkdes/customer/getBalance?accountNo=${account.accountNo}&meterNo=${account.meterNo}`
      );
      const balJson = balResult.data;
      if (!balJson || balJson.code !== 200 || !balJson.data) {
        throw new Error(balJson?.desc || 'Failed to fetch balance data from DESCO');
      }

      const liveBalance = Number(balJson.data.balance);
      const realMeterNo = balJson.data.meterNo || account.meterNo;
      // NOTE: balJson.data.currentMonthConsumption is BDT cost, NOT kWh.
      // The actual kWh reading comes from consumedUnit in the daily consumption endpoint.
      // We initialise to 0 here and derive it below from consumedUnit.
      let liveMonthlyKwh = 0;

      // 2. Fetch daily consumption for last 30 days (1 month) — also via SW proxy
      const today = new Date();
      const dateTo = today.toISOString().split('T')[0];
      const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
      const dateFrom = thirtyDaysAgo.toISOString().split('T')[0];

      const consResult = await extensionFetch(
        `https://prepaid.desco.org.bd/api/tkdes/customer/getCustomerDailyConsumption?accountNo=${account.accountNo}&meterNo=${realMeterNo}&dateFrom=${dateFrom}&dateTo=${dateTo}`
      );
      let yesterdayCost = account.yesterdayUsage || 0;
      
      const consJson = consResult.data;
      if (consJson && consJson.code === 200 && Array.isArray(consJson.data) && consJson.data.length > 0) {
          // Sort ascending by date so the latest entry is last
          const list = consJson.data.sort((a, b) => a.date.localeCompare(b.date));

          // consumedUnit is a cumulative all-time meter reading (never resets).
          // consumedTaka resets at month boundary, so we use that to find the billing month start.
          // The correct base is the LAST entry from the PREVIOUS month (e.g. Jun 30),
          // so that the first day of the current month (Jul 01) is included in the delta.
          const latestEntry = list[list.length - 1];
          const currentMonthStr = latestEntry.date.split('-').slice(0, 2).join('-'); // 'yyyy-MM'
          const lastOfPrevMonth = [...list].reverse().find(e => !e.date.startsWith(currentMonthStr));
          const baseUnit = lastOfPrevMonth
            ? Number(lastOfPrevMonth.consumedUnit)
            : Number(list.find(e => e.date.startsWith(currentMonthStr))?.consumedUnit ?? latestEntry.consumedUnit);
          liveMonthlyKwh = Number(Math.max(0, Number(latestEntry.consumedUnit) - baseUnit).toFixed(3));

          for (let i = 0; i < list.length; i++) {
            const current = list[i];
            const prev = i > 0 ? list[i - 1] : null;

            let dailyKwh = 0;
            let dailyCost = 0;

            if (prev) {
              // Wrap in Number() — DESCO API returns these fields as JSON strings
              const curUnit  = Number(current.consumedUnit);
              const prevUnit = Number(prev.consumedUnit);
              const curTaka  = Number(current.consumedTaka);
              const prevTaka = Number(prev.consumedTaka);

              dailyKwh = Number(Math.max(0, curUnit - prevUnit).toFixed(3));

              const currentMonth = current.date.split('-')[1];
              const prevMonth    = prev.date.split('-')[1];
              if (currentMonth === prevMonth) {
                dailyCost = Number(Math.max(0, curTaka - prevTaka).toFixed(2));
              } else {
                // Month boundary — consumedTaka resets, so today's value is the full daily cost
                dailyCost = Number(curTaka.toFixed(2));
              }

              // Fallback: If odometer reading did not update/change (dailyKwh is 0) but there is a positive cost,
              // estimate the daily kWh using the active slab rate so the kWh line on the graph isn't off.
              if (dailyKwh === 0 && dailyCost > 5.0) {
                const monthlyKwhAtDate = Number(current.consumedUnit) > 0 
                  ? Number(current.consumedUnit) - baseUnit 
                  : liveMonthlyKwh;
                const slabDetails = getSlabDetails(Math.max(0, monthlyKwhAtDate), 'desco');
                const rate = slabDetails ? slabDetails.rate : 6.18;
                dailyKwh = Number((dailyCost / rate).toFixed(3));
              }
            }

            if (dailyKwh > 0 || dailyCost > 0) {
              await db.addHistoryRecord(accountId, current.date, dailyKwh, dailyCost);
            }
          }

          if (list.length >= 2) {
            const last    = list[list.length - 1];
            const secLast = list[list.length - 2];
            const lastTaka    = Number(last.consumedTaka);
            const secLastTaka = Number(secLast.consumedTaka);
            const lastMonth    = last.date.split('-')[1];
            const secLastMonth = secLast.date.split('-')[1];
            if (lastMonth === secLastMonth) {
              yesterdayCost = Number(Math.max(0, lastTaka - secLastTaka).toFixed(2));
            } else {
              yesterdayCost = Number(lastTaka.toFixed(2));
            }
          }
      }

      // 3. Compute active slab details
      const slabStats = getSlabDetails(liveMonthlyKwh, 'desco');

      // 4. Update and return account
      const updatedAccount = {
        ...account,
        balance: liveBalance,
        monthlyKwh: liveMonthlyKwh,
        yesterdayUsage: yesterdayCost,
        currentSlab: slabStats.index,
        slabUsage: Number((liveMonthlyKwh - slabStats.slabMin).toFixed(2)),
        lastUpdated: new Date().toISOString()
      };

      await db.saveAccount(updatedAccount);
      return updatedAccount;
    } catch (err) {
      console.error("DESCO live sync failed:", err);
      throw err;
    }
  }
};
export { DISTRIBUTORS };
