import React, { useState, useEffect } from 'react';
import { db } from './storage';
import { providers, DISTRIBUTORS } from './providers';
import { calculateDaysRemaining, getSlabDetails, calculateCost, calculateBreakdown } from './calculations';

// NERC progressive tier-proportional consumption bar.
// Splits into 6 segments matching Bangladesh progressive tariff ranges (0-50, 50-75, 75-200, 200-300, 300-400, 400-600).
// Each segment's fill color reveals a portion of the green (0 kWh) to red (600 kWh) gradient.
function ChargeBar({ monthlyKwh = 0, loading = false }) {
  const TIER_RANGES = [
    { min: 0,   max: 50,  weight: 50 / 600 },
    { min: 50,  max: 75,  weight: 25 / 600 },
    { min: 75,  max: 200, weight: 125 / 600 },
    { min: 200, max: 300, weight: 100 / 600 },
    { min: 300, max: 400, weight: 100 / 600 },
    { min: 400, max: 600, weight: 200 / 600 },
  ];

  const getColorForKwh = (val) => {
    const clamped = Math.max(0, Math.min(600, val));
    if (clamped <= 300) {
      const ratio = clamped / 300;
      const r = Math.round(0x2E + (0xB2 - 0x2E) * ratio);
      const g = Math.round(0x7D + (0x54 - 0x7D) * ratio);
      const b = Math.round(0x3A + (0x09 - 0x3A) * ratio);
      return `rgb(${r}, ${g}, ${b})`;
    } else {
      const ratio = (clamped - 300) / 300;
      const r = Math.round(0xB2 + (0xC2 - 0xB2) * ratio);
      const g = Math.round(0x54 + (0x2A - 0x54) * ratio);
      const b = Math.round(0x09 + (0x21 - 0x09) * ratio);
      return `rgb(${r}, ${g}, ${b})`;
    }
  };

  return (
    <div
      className="charge-bar"
      style={{ display: 'flex', gap: '3px', height: '8px', width: '100%', margin: '8px 0' }}
      title={`${monthlyKwh.toFixed(1)} kWh consumed this month`}
    >
      {TIER_RANGES.map((tier, idx) => {
        const rangeWidth = tier.max - tier.min;
        const consumed = Math.max(0, Math.min(monthlyKwh - tier.min, rangeWidth));
        const fillPct = loading ? 0 : (consumed / rangeWidth) * 100;
        const startColor = getColorForKwh(tier.min);
        const endColor = getColorForKwh(tier.max);

        return (
          <div
            key={idx}
            className="charge-segment"
            style={{
              width: `${tier.weight * 100}%`,
              height: '100%',
              borderRadius: '2px',
              background: 'var(--border-color)',
              overflow: 'hidden',
              flexShrink: 0
            }}
          >
            <div
              style={{
                width: `${fillPct}%`,
                height: '100%',
                background: `linear-gradient(to right, ${startColor}, ${endColor})`,
                transition: 'width 0.3s ease'
              }}
            />
          </div>
        );
      })}
    </div>
  );
}


function App() {
  // Navigation: 'dashboard' | 'detail'
  const [view, setView] = useState('dashboard');

  // Data
  const [accounts, setAccounts] = useState([]);
  const [selectedAccountId, setSelectedAccountId] = useState(null);
  const [history, setHistory] = useState([]);
  const [showAddModal, setShowAddModal] = useState(false);

  // Add Account Form inputs
  const [nickname, setNickname] = useState('');
  const [provider, setProvider] = useState('desco');
  const [accountNo, setAccountNo] = useState('');
  const [meterNo, setMeterNo] = useState('');
  const [balance, setBalance] = useState('1000');
  const [monthlyKwh, setMonthlyKwh] = useState('0');
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncError, setSyncError] = useState(null);

  // Simulator / operations state
  const [topUpAmount, setTopUpAmount] = useState('');
  const [isSimulating, setIsSimulating] = useState(false);

  // Sync action
  const handleSync = async (id = selectedAccountId) => {
    if (!id || isSyncing) return;
    setIsSyncing(true);
    setSyncError(null);
    try {
      await providers.syncAccount(id);
      await refreshAccounts(id, false);
    } catch (err) {
      console.error('Auto-sync failed:', err);
      setSyncError(err.message || 'Failed to sync with live API');
    } finally {
      setIsSyncing(false);
    }
  };

  // Simulate 24H for mock accounts
  const handleSimulate = async () => {
    if (!selectedAccountId || isSimulating) return;
    setIsSimulating(true);
    try {
      await providers.simulateDay(selectedAccountId);
      await refreshAccounts(selectedAccountId, false);
    } catch (err) {
      console.error('Simulate failed:', err);
    } finally {
      setIsSimulating(false);
    }
  };

  // Reset billing cycle for mock accounts
  const handleResetCycle = async () => {
    if (!selectedAccountId) return;
    if (!window.confirm('Reset monthly usage to zero? This simulates a new billing cycle.')) return;
    try {
      await providers.resetBillingCycle(selectedAccountId);
      await refreshAccounts(selectedAccountId, false);
    } catch (err) {
      console.error('Reset failed:', err);
    }
  };

  // Top up balance for mock accounts
  const handleTopUp = async () => {
    const amt = parseFloat(topUpAmount);
    if (!selectedAccountId || isNaN(amt) || amt <= 0) return;
    try {
      await providers.topUpBalance(selectedAccountId, amt);
      setTopUpAmount('');
      await refreshAccounts(selectedAccountId, false);
    } catch (err) {
      console.error('Top-up failed:', err);
    }
  };

  // Initial load
  useEffect(() => {
    async function loadData() {
      await db.init();
      await refreshAccounts();
    }
    loadData();
  }, []);

  // Auto-sync active DESCO account when entering detail view
  useEffect(() => {
    if (view !== 'detail' || !selectedAccountId) return;
    const active = accounts.find(a => a.id === selectedAccountId);
    if (active && active.distributor === 'desco') {
      handleSync(selectedAccountId);
    }
  }, [view, selectedAccountId]);

  // Fetch accounts
  const refreshAccounts = async (selectId = null, navigate = true) => {
    const list = await db.getAccounts();
    setAccounts(list);

    if (list.length === 0) {
      setSelectedAccountId(null);
      setHistory([]);
      setShowAddModal(true);
      return;
    }

    const targetId = selectId && list.some(a => a.id === selectId)
      ? selectId
      : selectedAccountId && list.some(a => a.id === selectedAccountId)
        ? selectedAccountId
        : list[0].id;

    setSelectedAccountId(targetId);
    await loadHistory(targetId);
  };

  // Fetch history for selected account
  const loadHistory = async (id) => {
    if (!id) return;
    const logs = await db.getHistory(id);
    setHistory(logs);
  };

  // Open account detail
  const openDetail = async (acc) => {
    setSyncError(null);
    setSelectedAccountId(acc.id);
    await loadHistory(acc.id);
    setView('detail');
  };

  // Back to dashboard
  const goBack = () => {
    setView('dashboard');
    setSyncError(null);
  };

  // Delete account click
  const handleDelete = async () => {
    if (!selectedAccountId) return;
    if (!window.confirm('Are you sure you want to delete this account?')) return;
    const remaining = await db.deleteAccount(selectedAccountId);
    const nextSelect = remaining.length > 0 ? remaining[0].id : null;
    await refreshAccounts(nextSelect);
    setView('dashboard');
  };

  // Add Account form submission
  const handleAddAccountSubmit = async (e) => {
    e.preventDefault();
    if (!nickname.trim() || !accountNo.trim() || !meterNo.trim()) {
      alert('Please fill in all required fields.');
      return;
    }
    if (!/^\d+$/.test(accountNo) || !/^\d+$/.test(meterNo)) {
      alert('Account number and Meter number must contain digits only.');
      return;
    }

    const isDesco = provider === 'desco';
    const newAcc = {
      nickname: nickname.trim(),
      distributor: provider,
      accountNo: accountNo.trim(),
      meterNo: meterNo.trim(),
      balance: isDesco ? 0 : (parseFloat(balance) || 0),
      monthlyKwh: isDesco ? 0 : (parseFloat(monthlyKwh) || 0),
      yesterdayUsage: 0,
    };

    const list = await db.saveAccount(newAcc);
    const created = list[list.length - 1];

    setNickname('');
    setProvider('desco');
    setAccountNo('');
    setMeterNo('');
    setBalance('1000');
    setMonthlyKwh('0');
    setShowAddModal(false);

    if (isDesco) {
      try { await providers.syncAccount(created.id); } catch (_) {}
    }

    await refreshAccounts(created.id);
  };

  // ── Helpers ──────────────────────────────────────────────────────────
  const getAccountStats = (acc) => {
    const days = calculateDaysRemaining(acc.balance, acc.yesterdayUsage);
    const slab = getSlabDetails(acc.monthlyKwh, acc.distributor);
    const dist = DISTRIBUTORS[acc.distributor] || DISTRIBUTORS.default;
    const low  = days <= 2.0 && days !== Infinity && acc.yesterdayUsage > 0;
    return { days, slab, dist, low };
  };

  const formatDate = (dateStr) => {
    const parts = dateStr.split('-');
    if (parts.length !== 3) return dateStr;
    return new Date(parts[0], parts[1] - 1, parts[2])
      .toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  };

  const activeAccount = accounts.find(a => a.id === selectedAccountId);
  const activeStats   = activeAccount ? getAccountStats(activeAccount) : null;
  const maxLoadLastMonth = history.length > 0
    ? (Math.max(...history.map(h => h.consumptionKwh)) / 10).toFixed(2)
    : '--';

  // ── Extended card metrics ─────────────────────────────────────────────
  const computeCardMetrics = (acc) => {
    const dist = DISTRIBUTORS[acc.distributor] || DISTRIBUTORS.default;
    const daysElapsed   = history.length || 1;
    const dailyAvgKwh   = acc.monthlyKwh / daysElapsed;
    const now           = new Date();
    const daysInMonth   = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    // yesterday is the last full day we have data for, so remaining = daysInMonth - (today - 1)
    const daysRemaining = Math.max(daysInMonth - (now.getDate() - 1), 0);
    const projectedKwh  = Math.min(acc.monthlyKwh + dailyAvgKwh * daysRemaining, 9999);
    const spendThisMonth = calculateCost(acc.monthlyKwh, acc.distributor);
    const forecastBill   = calculateCost(projectedKwh, acc.distributor);
    const forecastKwh    = projectedKwh;
    const forecastBreakdown = calculateBreakdown(projectedKwh, acc.distributor);
    const yesterdayBill  = acc.yesterdayUsage;
    const currency = dist.currency;
    return { 
      spendThisMonth, 
      forecastBill, 
      forecastKwh, 
      forecastBreakdown, 
      yesterdayBill, 
      currency,
      daysElapsed,
      dailyAvgKwh,
      daysRemaining,
      monthlyKwh: acc.monthlyKwh
    };
  };

  // ── Render ───────────────────────────────────────────────────────────
  return (
    <div className="app-container">
      {/* ── Header ── */}
      <header className="app-header">
        <div className="logo-area">
          <div className="title-sub">
            <div className="logo-area" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <svg viewBox="0 0 100 100" width="28" height="28" style={{ flexShrink: 0 }} role="img" aria-label="Boner Mohis">
                <g transform="translate(8.140,13.163) scale(0.8372)">
                  <path d="M 14 56 L 38 46 L 62 52 L 86 32" fill="none" stroke="currentColor" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" />
                  <circle cx="86" cy="32" r="7" fill="var(--accent)" />
                </g>
              </svg>
              <span style={{ fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: '24px' }}>Boner Mohis</span>
            </div>
            <span className="sub-label">Prepaid Electricity Meter Genius</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          {view === 'dashboard' && (
            <button
              id="btn-toggle-add-form"
              className="btn-icon"
              title="Add New Account"
              onClick={() => setShowAddModal(true)}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
              </svg>
            </button>
          )}
        </div>
      </header>

      <main className="app-body">

        {/* ══════════════════════════════════════════════════════════════
            VIEW: DASHBOARD — account summary cards grid
        ══════════════════════════════════════════════════════════════ */}
        {view === 'dashboard' && (
          <section className="dashboard-home">
            {accounts.length === 0 ? (
              <div className="empty-state glass-panel">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                  stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                  className="empty-icon">
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="8" x2="12" y2="12" />
                  <line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
                <p>No accounts added yet</p>
                <button className="btn-submit" style={{ marginTop: 16 }} onClick={() => setShowAddModal(true)}>
                  Add first account
                </button>
              </div>
            ) : (
              <div className="account-cards-grid">
                {accounts.map(acc => {
                  const { days, slab, dist, low } = getAccountStats(acc);
                  return (
                    <button
                      key={acc.id}
                      className="account-summary-card"
                      onClick={() => openDetail(acc)}
                    >
                      {/* Card top row */}
                      <div className="asc-header">
                        <div className="asc-names">
                          <span className="asc-nickname">{acc.nickname}</span>
                          <span className="provider-badge">{dist.name}</span>
                        </div>
                        {low && (
                          <span className="asc-low-badge">Low balance</span>
                        )}
                      </div>

                      {/* Balance */}
                      <div className="asc-balance">
                        <span className="asc-currency">{dist.currency}</span>
                        <span className="asc-amount">{acc.balance.toFixed(2)}</span>
                      </div>

                      {/* Charge Bar showing progressive consumption */}
                      <ChargeBar monthlyKwh={acc.monthlyKwh} />

                      {/* Redesigned dashboard cards — 2×2 grid */}
                      <div className="dashboard-stats-grid">
                        <div className="stat-card">
                          <span className="stat-caption">current tier</span>
                          <span className="stat-value">{slab.label.split(' (')[0]}</span>
                        </div>
                        <div className="stat-card">
                          <span className="stat-caption">Consumed this month</span>
                          <span className="stat-value">
                            {acc.monthlyKwh.toFixed(0)} <span className="stat-unit">kWh</span>
                          </span>
                        </div>
                        <div className="stat-card">
                          <span className="stat-caption">Yesterday bill</span>
                          <span className="stat-value">
                            {dist.currency}{acc.yesterdayUsage.toFixed(2)}
                          </span>
                        </div>
                        <div className={`stat-card highlight-card ${low ? 'low-balance-warning' : 'good-balance'}`}>
                          <span className="stat-caption">Forecast remaining</span>
                          <span className="stat-value">
                            {days === Infinity ? '--' : days} <span className="stat-unit">days</span>
                          </span>
                        </div>
                      </div>

                      <div className="asc-tap-hint">Tap to view details</div>
                    </button>
                  );
                })}
              </div>
            )}
          </section>
        )}

        {/* ══════════════════════════════════════════════════════════════
            VIEW: DETAIL — full metrics for selected account
        ══════════════════════════════════════════════════════════════ */}
        {view === 'detail' && activeAccount && activeStats && (() => {
          const remainingUnits = Math.round(activeAccount.balance / activeStats.slab.rate);
          return (
            <div id="dashboard-view" className="dashboard-card glass-panel">
              {/* Low Balance Alert Banner */}
              {activeStats.low && (
                <div id="low-balance-alert" className="alert-banner">
                  <svg className="alert-icon-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                    fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"
                    strokeLinejoin="round"
                    style={{ width: 15, height: 15, marginRight: 6, flexShrink: 0, color: 'var(--state-low)' }}>
                    <circle cx="12" cy="12" r="10" />
                    <line x1="12" y1="8" x2="12" y2="12" />
                    <line x1="12" y1="16" x2="12.01" y2="16" />
                  </svg>
                  <span className="alert-text">
                    Home meter · {remainingUnits} units · ~{activeStats.days} days left at your usual usage (estimate) · as of {new Date(activeAccount.lastUpdated).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit', hour12: true }).toLowerCase()}, manual entry
                  </span>
                </div>
              )}

              <div className="detail-layout-container">
                {/* Row #1: Split main details & slab visualizer */}
                <div className="detail-row-one">
                  {/* Row #1 Left Col: Remaining Balance & 3 cards in a row */}
                  <div className="detail-row-one-left">
                    {/* Account identity header */}
                    <div className="card-header">
                      <div className="account-meta-with-back" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <button className="btn-back" onClick={goBack} title="Back to Dashboard" aria-label="Back to Dashboard">
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                            <polyline points="15 18 9 12 15 6" />
                          </svg>
                        </button>
                        <div className="account-meta">
                          <span className="nickname-title">{activeAccount.nickname}</span>
                          <span className="account-no-label">A/C &middot; {activeAccount.accountNo} &middot; {activeAccount.distributor.toUpperCase()}</span>
                        </div>
                      </div>
                      <div className="account-actions" style={{ display: 'flex', gap: '8px' }}>
                        <button
                          className={`btn-icon${isSyncing ? ' spinning' : ''}`}
                          title="Sync account"
                          onClick={() => handleSync()}
                          disabled={isSyncing}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                            <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.85.99 6.57 2.61L21 8" />
                            <polyline points="21 3 21 8 16 8" />
                          </svg>
                        </button>
                        <button
                          className="btn-icon btn-icon-danger"
                          title="Delete account"
                          onClick={handleDelete}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                            <polyline points="3 6 5 6 21 6" />
                            <path d="M19 6l-1 14H6L5 6" />
                            <path d="M10 11v6M14 11v6" />
                            <path d="M9 6V4h6v2" />
                          </svg>
                        </button>
                      </div>
                    </div>
                    {/* Balance */}
                    <div className="balance-container">
                      <div className="balance-main">
                        <span id="display-currency" className="currency-symbol">
                          {activeStats.dist?.currency || '৳'}
                        </span>
                        <span id="display-balance" className="balance-value">
                          {activeAccount.balance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </span>
                      </div>
                      <span className="balance-label">Remaining balance</span>
                      <div className="balance-freshness" style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>
                        as of {activeAccount.lastUpdated ? new Date(activeAccount.lastUpdated).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit', hour12: true }).toLowerCase() : 'recently'} &middot; {activeAccount.distributor === 'desco' ? 'synced' : 'manual entry'}
                      </div>
                    </div>

                    {/* 8-card info grid — 4 cols × 2 rows */}
                    {(() => {
                      const m = computeCardMetrics(activeAccount);
                      const fmt2 = (n) => n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                      return (
                        <div className="info-grid">
                          <div className="info-item">
                            <span className="info-caption">Spend this month</span>
                            <span className="info-value">{m.currency}{fmt2(m.spendThisMonth)}</span>
                          </div>
                          <div className="info-item">
                            <span className="info-caption">Consumed this month</span>
                            <span className="info-value">
                              {activeAccount.monthlyKwh.toFixed(0)} <span className="stat-unit">kWh</span>
                            </span>
                          </div>
                          <div className="info-item">
                            <span className="info-caption">Max load last month</span>
                            <span className="info-value">
                              {maxLoadLastMonth} <span className="stat-unit">kW</span>
                            </span>
                          </div>
                          <div className="info-item">
                            <span className="info-caption">Yesterday bill</span>
                            <span className="info-value">{m.currency}{fmt2(m.yesterdayBill)}</span>
                          </div>
                          <div className="info-item info-item--tooltip">
                            <span className="info-caption">
                              Forecast bill <span className="hover-info-badge">i</span>
                            </span>
                            <span className="info-value">{m.currency}{fmt2(m.forecastBill)}</span>
                            <div className="tier-tooltip">
                              <div className="tier-tooltip-title">Tiered billing breakdown</div>
                              <table className="tier-table">
                                <thead>
                                  <tr>
                                    <th>Tier</th><th>Units</th><th>Rate</th><th>Cost</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {m.forecastBreakdown.map((row, i) => (
                                    <tr key={i}>
                                      <td>{row.name}</td>
                                      <td>{row.units} kWh</td>
                                      <td>৳{row.rate.toFixed(2)}</td>
                                      <td>৳{fmt2(row.cost)}</td>
                                    </tr>
                                  ))}
                                </tbody>
                                <tfoot>
                                  <tr>
                                    <td colSpan="3">Total</td>
                                    <td>৳{fmt2(m.forecastBill)}</td>
                                  </tr>
                                </tfoot>
                              </table>
                              <div className="tier-tooltip-note">{m.forecastKwh.toFixed(0)} kWh projected</div>
                            </div>
                          </div>
                          <div className="info-item info-item--tooltip">
                            <span className="info-caption">
                              Forecast consumption <span className="hover-info-badge">i</span>
                            </span>
                            <span className="info-value">
                              {m.forecastKwh.toFixed(0)} <span className="stat-unit">kWh</span>
                            </span>
                            <div className="tier-tooltip">
                              <div className="tier-tooltip-title">Forecast Breakdown</div>
                              <table className="tier-table">
                                <tbody>
                                  <tr>
                                    <td>Consumed so far</td>
                                    <td>{m.monthlyKwh.toFixed(1)} kWh</td>
                                  </tr>
                                  <tr>
                                    <td>Daily average</td>
                                    <td>{m.dailyAvgKwh.toFixed(2)} kWh/day</td>
                                  </tr>
                                  <tr>
                                    <td>Days remaining</td>
                                    <td>{m.daysRemaining} days</td>
                                  </tr>
                                  <tr>
                                    <td>Projected remainder</td>
                                    <td>{(m.dailyAvgKwh * m.daysRemaining).toFixed(1)} kWh</td>
                                  </tr>
                                </tbody>
                                <tfoot>
                                  <tr>
                                    <td>Forecast Total</td>
                                    <td>{m.forecastKwh.toFixed(1)} kWh</td>
                                  </tr>
                                </tfoot>
                              </table>
                              <div className="tier-tooltip-note">Formula: Consumed + (Avg × Days Left)</div>
                            </div>
                          </div>
                          <div className={`info-item highlight-item ${activeStats.low ? 'low-balance-warning' : 'good-balance'}`}>
                            <span className="info-caption">Forecast remaining</span>
                            <span className="info-value">
                              {activeStats.days === Infinity ? '--' : activeStats.days} <span className="stat-unit">days</span>
                            </span>
                          </div>
                        </div>
                      );
                    })()}
                  </div>

                  {/* Row #1 Right Col: Current billing tier */}
                  <div className="detail-row-one-right">
                    {activeStats.slab && (
                      <div className="slab-visualizer-container glass-item" style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                        <div className="slab-header">
                          <span className="slab-title">Current billing tier</span>
                          <span className="slab-value-label">{activeStats.slab.label}</span>
                        </div>
                        <div className="slab-bar-wrapper">
                          <div className="progress-bar-container">
                            <div
                              className="progress-fill"
                              style={{
                                width: `${activeStats.slab.percentage}%`,
                                background: 'linear-gradient(to right, #2E7D3A 0%, #8F9B28 30%, #B25409 65%, #C22A21 100%)',
                                backgroundSize: activeStats.slab.percentage > 0
                                  ? `${(100 / activeStats.slab.percentage) * 100}% 100%`
                                  : '100% 100%',
                                backgroundRepeat: 'no-repeat'
                              }}
                            />
                          </div>
                          {/* Arrow marker indicating current consumption */}
                          <div className="slab-marker" style={{ left: `${activeStats.slab.percentage}%` }}>
                            <span className="slab-marker-label">{activeAccount.monthlyKwh.toFixed(1)} kWh</span>
                            <span className="slab-marker-arrow">▼</span>
                          </div>
                        </div>
                        <div className="slab-range-labels">
                          <span className="slab-range-min">{activeStats.slab.slabMin} kWh</span>
                          <span className="slab-range-max">
                            {activeStats.slab.slabMax === Infinity ? '∞' : `${activeStats.slab.slabMax} kWh`}
                          </span>
                        </div>
                        <div className="slab-footer">
                          <span className="slab-foot-text">
                            {activeAccount.slabUsage.toFixed(2)} kWh consumed in tier
                          </span>
                          <span className="slab-foot-pct">{activeStats.slab.percentage}% used</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Row #2: Graph */}
                <div className="detail-row-two">
                  <section className="history-section">
                    <h3 className="section-title">Usage & Cost Trends</h3>
                    <UsageChart history={history} currency={activeStats.dist?.currency || '৳'} />
                  </section>
                </div>

                {/* Row #3: Recent usage logs */}
                <div className="detail-row-three">
                  <section className="history-section">
                    <h3 className="section-title">Recent Usage Logs</h3>
                    <div className="history-list">
                      {history.length === 0 ? (
                        <div className="history-row">
                          <span className="history-date">No usage logs recorded yet.</span>
                        </div>
                      ) : (
                        history.slice(0, 10).map((item, idx) => (
                          <div key={idx} className="history-row">
                            <span className="history-date">{formatDate(item.date)}</span>
                            <div className="history-metrics">
                              <span className="history-kwh">{item.consumptionKwh.toFixed(1)} kWh</span>
                              <span className="history-cost">
                                {activeStats.dist?.currency}{item.cost.toFixed(2)}
                              </span>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </section>
                </div>

                {/* Row #4: Simulator / Live Operations */}
                <div className="detail-row-simulator">
                  <div className="simulator-card glass-item">
                    <h3 className="section-title">
                      {activeAccount.distributor === 'desco' ? 'LIVE API OPERATIONS' : 'SIMULATOR CONTROLS'}
                    </h3>
                    {activeAccount.distributor === 'desco' ? (
                      <div className="sim-action-row">
                        <button
                          className={`btn-sim-primary${isSyncing ? ' spinning' : ''}`}
                          onClick={() => handleSync()}
                          disabled={isSyncing}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                            style={{ width: 14, height: 14 }}>
                            <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.85.99 6.57 2.61L21 8" />
                            <polyline points="21 3 21 8 16 8" />
                          </svg>
                          {isSyncing ? 'Syncing…' : 'Sync Live'}
                        </button>
                        {syncError && (
                          <p className="sim-error-text">{syncError}</p>
                        )}
                      </div>
                    ) : (
                      <>
                        <div className="sim-action-row">
                          <button
                            className={`btn-sim-primary${isSimulating ? ' spinning' : ''}`}
                            onClick={handleSimulate}
                            disabled={isSimulating}
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                              stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                              style={{ width: 14, height: 14 }}>
                              <polygon points="5 3 19 12 5 21 5 3" />
                            </svg>
                            {isSimulating ? 'Simulating…' : 'Simulate 24H'}
                          </button>
                          <button className="btn-sim-secondary" onClick={handleResetCycle}>
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                              stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                              style={{ width: 14, height: 14 }}>
                              <path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.85.99 6.57 2.61L21 8" />
                              <polyline points="21 3 21 8 16 8" />
                            </svg>
                            Reset Cycle
                          </button>
                        </div>
                        <div className="top-up-form">
                          <div className="input-group">
                            <span className="input-prefix">৳</span>
                            <input
                              type="number"
                              placeholder="Top-up amount"
                              min="1"
                              value={topUpAmount}
                              onChange={(e) => setTopUpAmount(e.target.value)}
                              onKeyDown={(e) => e.key === 'Enter' && handleTopUp()}
                            />
                            <button className="btn-accent" onClick={handleTopUp}>Top Up</button>
                          </div>
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })()}

        {/* ── Add Account Modal ── */}
        {showAddModal && (
          <div className="modal-overlay">
            <div className="modal-card glass-panel">
              <div className="modal-header">
                <h3>Add electricity account</h3>
                <button
                  className="btn-close-icon"
                  onClick={() => setShowAddModal(false)}
                  disabled={accounts.length === 0}
                >
                  &times;
                </button>
              </div>

              <form onSubmit={handleAddAccountSubmit} className="modal-form">
                <div className="form-group">
                  <label>Nickname</label>
                  <input
                    type="text"
                    placeholder="e.g. My apartment, shop"
                    required
                    value={nickname}
                    onChange={(e) => setNickname(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label>Distributor provider</label>
                  <select
                    className="glass-select"
                    required
                    value={provider}
                    onChange={(e) => setProvider(e.target.value)}
                  >
                    <option value="desco">DESCO (Dhaka Electric)</option>
                  </select>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Account number</label>
                    <input
                      type="text"
                      placeholder="8-digit account ID"
                      required
                      pattern="\d+"
                      value={accountNo}
                      onChange={(e) => setAccountNo(e.target.value)}
                    />
                  </div>
                  <div className="form-group">
                    <label>Meter number</label>
                    <input
                      type="text"
                      placeholder="8-digit meter serial"
                      required
                      pattern="\d+"
                      value={meterNo}
                      onChange={(e) => setMeterNo(e.target.value)}
                    />
                  </div>
                </div>

                {provider !== 'desco' && (
                  <div className="form-row">
                    <div className="form-group">
                      <label>Initial balance (৳)</label>
                      <input
                        type="number"
                        placeholder="1500"
                        min="0"
                        required={provider !== 'desco'}
                        value={balance}
                        onChange={(e) => setBalance(e.target.value)}
                      />
                    </div>
                    <div className="form-group">
                      <label>Current month usage (kWh)</label>
                      <input
                        type="number"
                        placeholder="100"
                        min="0"
                        required={provider !== 'desco'}
                        value={monthlyKwh}
                        onChange={(e) => setMonthlyKwh(e.target.value)}
                      />
                    </div>
                  </div>
                )}

                <button type="submit" className="btn-submit">Add account</button>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

function UsageChart({ history, currency = '৳' }) {
  const [hoveredIdx, setHoveredIdx] = useState(null);

  if (!history || history.length === 0) {
    return (
      <div style={{ height: 120, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)', fontSize: '12px' }}>
        Not enough historical data to display chart.
      </div>
    );
  }

  // Safe extraction of current active month YYYY-MM
  const latestEntry = history.length > 0 ? history[0] : null;
  const latestDateStr = latestEntry && typeof latestEntry.date === 'string' ? latestEntry.date : '';
  const currentMonthPrefix = latestDateStr.length >= 7 
    ? latestDateStr.slice(0, 7) 
    : new Date().toISOString().slice(0, 7);

  const year = parseInt(currentMonthPrefix.split('-')[0], 10) || new Date().getFullYear();
  const month = parseInt(currentMonthPrefix.split('-')[1], 10) || (new Date().getMonth() + 1);
  const daysInMonth = new Date(year, month, 0).getDate();

  // Pre-populate all days of the current active month (1 to 28-31)
  const data = [];
  for (let day = 1; day <= daysInMonth; day++) {
    const dayStr = day.toString().padStart(2, '0');
    const dateKey = `${currentMonthPrefix}-${dayStr}`;
    const record = history.find(h => h.date === dateKey);

    if (record) {
      data.push({
        date: dateKey,
        day,
        hasData: true,
        consumptionKwh: isFinite(Number(record.consumptionKwh)) ? Number(record.consumptionKwh) : 0,
        cost: isFinite(Number(record.cost)) ? Number(record.cost) : 0,
      });
    } else {
      data.push({
        date: dateKey,
        day,
        hasData: false,
        consumptionKwh: null,
        cost: null,
      });
    }
  }

  // Find max values for scaling based only on valid data entries.
  const validKwhs = data.filter(d => d.hasData).map(d => d.consumptionKwh);
  const validCosts = data.filter(d => d.hasData).map(d => d.cost);
  const maxKwh = Math.max(...validKwhs, 0.1) * 1.15;
  const maxCost = Math.max(...validCosts, 0.1);
  const maxRate = 20.0;

  // SVG Chart Dimensions
  const width = 360;
  const height = 180;
  const paddingLeft = 35;
  const paddingRight = 35;
  const paddingTop = 25;
  const paddingBottom = 25;

  const chartWidth = width - paddingLeft - paddingRight;
  const chartHeight = height - paddingTop - paddingBottom;

  // Helper to map index to X coord
  const getX = (index) => {
    if (data.length <= 1) return paddingLeft + chartWidth / 2;
    return paddingLeft + (index / (data.length - 1)) * chartWidth;
  };

  // Helper to map kWh value to Y coord
  const getYKwh = (val) => {
    return paddingTop + chartHeight - (val / maxKwh) * chartHeight;
  };

  // Helper to map Cost value to Y coord
  const getYCost = (val) => {
    return paddingTop + chartHeight - (val / maxCost) * chartHeight;
  };

  // Helper to map Rate value to Y coord
  const getYRate = (val) => {
    return paddingTop + chartHeight - (val / maxRate) * chartHeight;
  };

  // Generate SVG path strings.
  // Each coordinate is validated with isFinite() before being appended;
  // an invalid point issues a moveTo for the *next* valid point so the
  // rest of the line still renders rather than the whole path going blank.
  let kwhPath = '';
  let costPath = '';
  let ratePath = '';

  data.forEach((d, i) => {
    if (!d.hasData) return; // Skip days with no data

    const x = getX(i);
    const yKwh = getYKwh(d.consumptionKwh);
    const yCost = getYCost(d.cost);
    const rate = d.consumptionKwh > 0 ? d.cost / d.consumptionKwh : 0;
    const yRate = getYRate(rate);

    // Guard: only emit coordinates that are real numbers
    if (isFinite(yKwh)) {
      kwhPath += kwhPath === '' ? `M ${x} ${yKwh}` : ` L ${x} ${yKwh}`;
    }
    if (isFinite(yCost)) {
      costPath += costPath === '' ? `M ${x} ${yCost}` : ` L ${x} ${yCost}`;
    }
    if (isFinite(yRate)) {
      ratePath += ratePath === '' ? `M ${x} ${yRate}` : ` L ${x} ${yRate}`;
    }
  });

  return (
    <div className="usage-chart-container">
      <svg viewBox={`0 0 ${width} ${height}`} width="100%" height="100%">
        {/* Horizontal grid lines */}
        {[0, 0.25, 0.5, 0.75, 1].map((pct, idx) => {
          const y = paddingTop + pct * chartHeight;
          return (
            <line
              key={idx}
              x1={paddingLeft}
              y1={y}
              x2={width - paddingRight}
              y2={y}
              stroke="rgba(255, 255, 255, 0.05)"
              strokeWidth="1"
            />
          );
        })}

        {/* Tariff slab reference lines (dashed gold) */}
        {[
          { rate: 5.26, label: '5.26' },
          { rate: 8.50, label: '8.50' },
          { rate: 9.10, label: '9.10' },
        ].map((slab, idx) => {
          const y = getYRate(slab.rate);
          return (
            <g key={`slab-${idx}`}>
              <line
                x1={paddingLeft}
                y1={y}
                x2={width - paddingRight}
                y2={y}
                stroke="rgba(212, 175, 87, 0.15)"
                strokeWidth="0.5"
                strokeDasharray="3,3"
              />
              <text
                x={width - paddingRight + 3}
                y={y + 2}
                fill="rgba(212, 175, 87, 0.5)"
                fontSize="5"
                textAnchor="start"
              >
                {slab.label}
              </text>
            </g>
          );
        })}

        {/* X Axis Labels (Dates) - selectively render to prevent overlap */}
        {data.map((d, i) => {
          const dayNum = d.day;
          const shouldShowLabel = dayNum === 1 || dayNum === daysInMonth || dayNum % 5 === 0;
          if (!shouldShowLabel) return null;

          const x = getX(i);
          return (
            <text
              key={i}
              x={x}
              y={height - 8}
              fill="var(--text-secondary)"
              fontSize="7"
              textAnchor="middle"
            >
              {dayNum}
            </text>
          );
        })}

        {/* Left Y Axis Label (kWh - Green) */}
        <text x={paddingLeft - 4} y={paddingTop - 8} fill="var(--state-ok)" fontSize="7" textAnchor="end">
          kWh
        </text>
        
        {/* Right Y Axis Label (Cost - Accent) */}
        <text x={width - paddingRight + 4} y={paddingTop - 8} fill="var(--accent)" fontSize="7" textAnchor="start">
          {currency}
        </text>

        {/* Draw lines */}
        {data.length > 1 && (
          <>
            {/* kWh Line */}
            <path
              d={kwhPath}
              fill="none"
              stroke="var(--state-ok)"
              strokeWidth="1.25"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{ filter: 'drop-shadow(0px 1px 2px rgba(46, 125, 58, 0.1))' }}
            />
            {/* Cost Line */}
            <path
              d={costPath}
              fill="none"
              stroke="var(--accent)"
              strokeWidth="1.25"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{ filter: 'drop-shadow(0px 1px 2px rgba(178, 84, 9, 0.1))' }}
            />
            {/* Rate Line (Dotted Gold) */}
            <path
              d={ratePath}
              fill="none"
              stroke="#D4AF37"
              strokeWidth="0.75"
              strokeDasharray="2,2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </>
        )}

        {/* Data points & hover zones */}
        {data.map((d, i) => {
          if (!d.hasData) return null;

          const x = getX(i);
          const yKwh = getYKwh(d.consumptionKwh);
          const yCost = getYCost(d.cost);
          const rate = d.consumptionKwh > 0 ? d.cost / d.consumptionKwh : 0;
          const yRate = getYRate(rate);

          const isHovered = hoveredIdx === i;

          return (
            <g key={i}>
              {/* Vertical indicator line on hover */}
              {isHovered && (
                <line
                  x1={x}
                  y1={paddingTop}
                  x2={x}
                  y2={paddingTop + chartHeight}
                  stroke="var(--border-color)"
                  strokeWidth="1.5"
                  strokeDasharray="2,2"
                />
              )}

              {/* kWh Dot */}
              <circle cx={x} cy={yKwh} r={isHovered ? 4 : 1} fill="var(--card-bg)" stroke="var(--state-ok)" strokeWidth={isHovered ? 1.5 : 0.5} />
              {/* Cost Dot */}
              <circle cx={x} cy={yCost} r={isHovered ? 4 : 1} fill="var(--card-bg)" stroke="var(--accent)" strokeWidth={isHovered ? 1.5 : 0.5} />
              {/* Rate Dot */}
              <circle cx={x} cy={yRate} r={isHovered ? 3 : 0.75} fill="var(--card-bg)" stroke="#D4AF37" strokeWidth={isHovered ? 1 : 0.5} />

              {/* Invisible interactive hover bar */}
              <rect
                x={x - (chartWidth / Math.max(1, data.length - 1)) / 2}
                y={paddingTop}
                width={chartWidth / Math.max(1, data.length - 1)}
                height={chartHeight}
                fill="transparent"
                style={{ cursor: 'pointer' }}
                onMouseEnter={() => setHoveredIdx(i)}
                onMouseLeave={() => setHoveredIdx(null)}
              />
            </g>
          );
        })}
      </svg>

      {/* Tooltip Overlay */}
      {hoveredIdx !== null && data[hoveredIdx] && (
        <div className="chart-tooltip glass-item">
          <div className="tooltip-date">{data[hoveredIdx].date}</div>
          <div className="tooltip-row">
            <span className="tooltip-dot cyan"></span>
            <span className="tooltip-label">Usage:</span>
            <span className="tooltip-value">{data[hoveredIdx].consumptionKwh.toFixed(2)} kWh</span>
          </div>
          <div className="tooltip-row">
            <span className="tooltip-dot orange"></span>
            <span className="tooltip-label">Cost:</span>
            <span className="tooltip-value">{currency}{data[hoveredIdx].cost.toFixed(2)}</span>
          </div>
          <div className="tooltip-row">
            <span className="tooltip-dot gold"></span>
            <span className="tooltip-label">Rate:</span>
            <span className="tooltip-value">
              {currency}{(data[hoveredIdx].consumptionKwh > 0 ? data[hoveredIdx].cost / data[hoveredIdx].consumptionKwh : 0).toFixed(2)}/unit
            </span>
          </div>
        </div>
      )}

      {/* Chart Legend */}
      <div className="chart-legend">
        <div className="legend-item">
          <span className="legend-line cyan"></span>
          <span>Usage (kWh)</span>
        </div>
        <div className="legend-item">
          <span className="legend-line orange"></span>
          <span>Cost ({currency})</span>
        </div>
        <div className="legend-item">
          <span className="legend-line gold dashed"></span>
          <span>Rate/Unit</span>
        </div>
      </div>
    </div>
  );
}

export default App;
