/**
 * Core electricity calculations and forecasting utilities.
 */

export const DISTRIBUTORS = {
  "desco": {
    name: "DESCO (Dhaka Electric)",
    currency: "৳",
    slabs: [
      { limit: 50, rate: 4.63 },
      { limit: 75, rate: 5.26 },
      { limit: 200, rate: 8.50 },
      { limit: 300, rate: 9.10 },
      { limit: 400, rate: 9.62 },
      { limit: 600, rate: 15.01 },
      { limit: Infinity, rate: 17.35 }
    ]
  },
  "default": {
    name: "DESCO (Dhaka Electric)",
    currency: "৳",
    slabs: [
      { limit: 50, rate: 4.63 },
      { limit: 75, rate: 5.26 },
      { limit: 200, rate: 8.50 },
      { limit: 300, rate: 9.10 },
      { limit: 400, rate: 9.62 },
      { limit: 600, rate: 15.01 },
      { limit: Infinity, rate: 17.35 }
    ]
  }
};

/**
 * Calculates progressive cost for a given consumption in kWh.
 * @param {number} kwh 
 * @param {string} provider 
 * @returns {number} Cost in local currency
 */
export function calculateCost(kwh, provider = 'default') {
  const dist = DISTRIBUTORS[provider] || DISTRIBUTORS.default;
  let remaining = kwh;
  let totalCost = 0;

  // Lifeline slab (0–50 kWh @ 4.63) only applies when total usage is ≤ 50 kWh.
  // When usage exceeds 50 kWh, all units 0–75 are billed at the First Step rate (5.26).
  const isLifeline = kwh <= 50.0;
  const startIdx = isLifeline ? 0 : 1;
  let prevLimit = 0.0;

  for (let i = startIdx; i < dist.slabs.length; i++) {
    const slab = dist.slabs[i];
    const rangeWidth = slab.limit - prevLimit;
    const consumedInSlab = Math.min(remaining, rangeWidth);

    totalCost += consumedInSlab * slab.rate;
    remaining -= consumedInSlab;
    prevLimit = slab.limit;

    if (remaining <= 0) break;
  }

  return Number(totalCost.toFixed(2));
}

const SLAB_NAMES = ['Lifeline', 'First Step', 'Second Step', 'Third Step', 'Fourth Step', 'Fifth Step', 'Sixth Step'];

/**
 * Returns per-slab line items for a given kWh consumption.
 * Used to render the tiered billing tooltip.
 * @param {number} kwh
 * @param {string} provider
 * @returns {{ name: string, units: number, rate: number, cost: number }[]}
 */
export function calculateBreakdown(kwh, provider = 'default') {
  const dist = DISTRIBUTORS[provider] || DISTRIBUTORS.default;
  let remaining = kwh;
  const lines = [];

  const isLifeline = kwh <= 50.0;
  const startIdx = isLifeline ? 0 : 1;
  let prevLimit = 0.0;

  for (let i = startIdx; i < dist.slabs.length; i++) {
    const slab = dist.slabs[i];
    const rangeWidth = slab.limit - prevLimit;
    const units = Math.min(remaining, rangeWidth);

    if (units > 0) {
      lines.push({
        name: SLAB_NAMES[i] || `Slab ${i + 1}`,
        units: Number(units.toFixed(2)),
        rate: slab.rate,
        cost: Number((units * slab.rate).toFixed(2)),
      });
    }

    remaining -= units;
    prevLimit = slab.limit;
    if (remaining <= 0) break;
  }

  return lines;
}

/**
 * Determines current billing slab details for total monthly consumption.
 * @param {number} kwh - Monthly consumption so far
 * @param {string} provider 
 * @returns {{
 *   index: number,
 *   rate: number,
 *   slabMin: number,
 *   slabMax: number,
 *   percentage: number,
 *   label: string
 * }}
 */
export function getSlabDetails(kwh, provider = 'default') {
  const dist = DISTRIBUTORS[provider] || DISTRIBUTORS.default;
  
  // Find which slab index the current kwh falls into
  let index = 0;
  for (let i = 0; i < dist.slabs.length; i++) {
    if (kwh <= dist.slabs[i].limit || dist.slabs[i].limit === Infinity) {
      index = i;
      break;
    }
  }

  const slab = dist.slabs[index];
  
  // Define slab names and ranges based on index
  const SLAB_CONFIGS = [
    { name: "Lifeline", min: 0, max: 50 },
    { name: "First Step", min: kwh > 50.0 ? 0 : 51, max: 75 },
    { name: "Second Step", min: 76, max: 200 },
    { name: "Third Step", min: 201, max: 300 },
    { name: "Fourth Step", min: 301, max: 400 },
    { name: "Fifth Step", min: 401, max: 600 },
    { name: "Sixth Step", min: 601, max: Infinity }
  ];

  const config = SLAB_CONFIGS[index] || { name: `Slab ${index + 1}`, min: 0, max: slab.limit };
  const slabMin = config.min;
  const slabMax = config.max;
  const rangeWidth = slabMax - slabMin;
  
  let percentage = 0;
  if (rangeWidth === Infinity) {
    percentage = 100;
  } else {
    percentage = Math.min(100, Math.max(0, ((kwh - slabMin) / rangeWidth) * 100));
  }

  const slabLabel = slabMax === Infinity 
    ? `${config.name} (> ${slabMin - 1} kWh)` 
    : `${config.name} (${slabMin}-${slabMax} kWh)`;

  return {
    index,
    rate: slab.rate,
    slabMin,
    slabMax,
    percentage: Number(percentage.toFixed(1)),
    label: slabLabel
  };
}

/**
 * Calculates remaining days of usage before balance runs out.
 * @param {number} balance - Current balance in currency
 * @param {number} yesterdayUsage - Consumption yesterday in currency
 * @returns {number} Days remaining (fractional) or Infinity / NaN
 */
export function calculateDaysRemaining(balance, yesterdayUsage) {
  if (yesterdayUsage <= 0) return Infinity;
  return Number((balance / yesterdayUsage).toFixed(1));
}
