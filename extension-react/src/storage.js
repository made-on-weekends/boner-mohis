/**
 * Local storage adapter supporting chrome.storage.local with a fallback to window.localStorage
 * for standard web-page previewing and testing.
 */

const isExtension = typeof chrome !== 'undefined' && chrome.storage && chrome.storage.local;

// Storage engine facade
const storageEngine = {
  get: async (keys) => {
    if (isExtension) {
      return new Promise((resolve) => {
        chrome.storage.local.get(keys, (res) => resolve(res));
      });
    } else {
      const res = {};
      const queryKeys = Array.isArray(keys) ? keys : [keys];
      for (const k of queryKeys) {
        const val = localStorage.getItem(k);
        res[k] = val ? JSON.parse(val) : undefined;
      }
      return res;
    }
  },
  set: async (items) => {
    if (isExtension) {
      return new Promise((resolve) => {
        chrome.storage.local.set(items, () => resolve());
      });
    } else {
      for (const [k, v] of Object.entries(items)) {
        localStorage.setItem(k, JSON.stringify(v));
      }
    }
  }
};

// Seed initial mock data if database is empty
const MOCK_ACCOUNTS = [
  {
    id: "acc_main_home",
    nickname: "Main Home",
    distributor: "desco",
    accountNo: "22056161",
    meterNo: "90082731",
    balance: 1450.00,
    lastUpdated: new Date().toISOString(),
    currentSlab: 2,
    slabUsage: 45.5,
    yesterdayUsage: 48.50, // Yesterday's cost in Taka
    monthlyKwh: 120.5 // Monthly total usage so far in kWh
  },
  {
    id: "acc_guest_cottage",
    nickname: "Guest Cottage",
    distributor: "desco",
    accountNo: "77635291",
    meterNo: "44526178",
    balance: 65.50, // Low balance!
    lastUpdated: new Date(Date.now() - 3600000).toISOString(),
    currentSlab: 1,
    slabUsage: 14.2,
    yesterdayUsage: 42.00, // Yesterday's cost in Taka
    monthlyKwh: 64.2 // Monthly total usage so far in kWh
  }
];

function generateMockHistory(baseKwh, baseCost) {
  const list = [];
  const today = new Date("2026-08-28T12:00:00Z");
  for (let i = 0; i < 30; i++) {
    const d = new Date(today.getTime() - i * 24 * 60 * 60 * 1000);
    const dateStr = d.toISOString().split('T')[0];
    const kwhVar = Math.sin(i * 0.7) * 2.5 + (i % 3 === 0 ? 3.0 : 0);
    const kwh = Number(Math.max(3.5, baseKwh + kwhVar).toFixed(1));
    const cost = Number((kwh * (baseCost / baseKwh)).toFixed(2));
    list.push({ date: dateStr, consumptionKwh: kwh, cost });
  }
  return list;
}

const MOCK_HISTORY = {
  "acc_main_home": generateMockHistory(7.0, 48.0),
  "acc_guest_cottage": generateMockHistory(5.5, 38.0)
};

export const db = {
  /**
   * Initializes storage with seed data if empty
   */
  init: async () => {
    const data = await storageEngine.get(["accounts", "usage_history"]);
    if (!data.accounts) {
      await storageEngine.set({
        accounts: MOCK_ACCOUNTS,
        usage_history: MOCK_HISTORY
      });
      console.log("Database initialized with seed data.");
    }
  },

  /**
   * Fetches all registered accounts
   */
  getAccounts: async () => {
    await db.init();
    const data = await storageEngine.get("accounts");
    return data.accounts || [];
  },

  /**
   * Saves a new account or updates an existing one
   */
  saveAccount: async (account) => {
    const accounts = await db.getAccounts();
    const existingIndex = accounts.findIndex(a => a.id === account.id);
    
    if (existingIndex !== -1) {
      accounts[existingIndex] = { ...accounts[existingIndex], ...account };
    } else {
      accounts.push({
        id: account.id || 'acc_' + Math.random().toString(36).substr(2, 9),
        balance: account.balance || 0,
        yesterdayUsage: account.yesterdayUsage || 0,
        currentSlab: account.currentSlab || 0,
        slabUsage: account.slabUsage || 0,
        monthlyKwh: account.monthlyKwh || 0,
        lastUpdated: new Date().toISOString(),
        ...account
      });
    }
    
    await storageEngine.set({ accounts });
    return accounts;
  },

  /**
   * Deletes an account and its usage history
   */
  deleteAccount: async (id) => {
    const accounts = await db.getAccounts();
    const filteredAccounts = accounts.filter(a => a.id !== id);
    await storageEngine.set({ accounts: filteredAccounts });

    const historyData = await storageEngine.get("usage_history");
    const history = historyData.usage_history || {};
    delete history[id];
    await storageEngine.set({ usage_history: history });
    
    return filteredAccounts;
  },

  /**
   * Fetches historical logs for a given account
   */
  getHistory: async (accountId) => {
    const data = await storageEngine.get("usage_history");
    const history = data.usage_history || {};
    return history[accountId] || [];
  },

  /**
   * Appends a daily usage log record and updates account states.
   * Deduplicates by date — if a record for that date already exists it is
   * updated in place rather than prepended again (mirrors Android Room logic).
   */
  addHistoryRecord: async (accountId, date, consumptionKwh, cost) => {
    const data = await storageEngine.get("usage_history");
    const history = data.usage_history || {};

    if (!history[accountId]) {
      history[accountId] = [];
    }

    const existingIdx = history[accountId].findIndex(r => r.date === date);
    if (existingIdx !== -1) {
      // Update existing record in place — no duplicate insertion
      history[accountId][existingIdx] = { date, consumptionKwh, cost };
    } else {
      // Insert at front (most-recent first) and cap at 30 records (1 month of daily logs)
      history[accountId].unshift({ date, consumptionKwh, cost });
      if (history[accountId].length > 30) {
        history[accountId] = history[accountId].slice(0, 30);
      }
    }

    await storageEngine.set({ usage_history: history });
  }
};
