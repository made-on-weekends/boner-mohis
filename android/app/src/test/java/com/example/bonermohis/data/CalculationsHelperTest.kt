package com.example.bonermohis.data

import org.junit.Assert.assertEquals
import org.junit.Test

class CalculationsHelperTest {

    @Test
    fun testCalculateCost_lifeline_desco() {
        // 50 kWh: Lifeline slab (50 * 4.63) = 231.50
        val cost50 = CalculationsHelper.calculateCost(50.0, "desco")
        assertEquals(231.50, cost50, 0.01)
    }

    @Test
    fun testCalculateCost_exceedsLifeline_desco() {
        // 100 kWh: Usage > 50, so Lifeline is SKIPPED.
        // First Step (0-75): 75 * 5.26 = 394.50
        // Second Step (75-200): 25 * 8.50 = 212.50
        // Total = 394.50 + 212.50 = 607.00
        val cost100 = CalculationsHelper.calculateCost(100.0, "desco")
        assertEquals(607.00, cost100, 0.01)
    }

    @Test
    fun testCalculateCost_124kWh_desco() {
        // 124.01 kWh: Lifeline bypassed
        // First Step (0-75): 75 * 5.26 = 394.50
        // Second Step (75-124.01): 49.01 * 8.50 = 416.585
        // Total ≈ 811.09
        val cost = CalculationsHelper.calculateCost(124.01, "desco")
        assertEquals(811.09, cost, 0.01)
    }

    @Test
    fun testGetSlabDetails_desco() {
        val details = CalculationsHelper.getSlabDetails(100.0, "desco")
        // 100 kWh is in Slab index 2 (Second Step 76-200 kWh)
        assertEquals(2, details.index)
        assertEquals(8.50, details.rate, 0.001)
    }

    @Test
    fun testGetSlabBreakdown_desco() {
        // 100 kWh breakdown
        val breakdown = CalculationsHelper.getSlabBreakdown(100.0, "desco")
        assertEquals(2, breakdown.size)
        
        // First Step: 75 kWh @ 5.26 = 394.50
        assertEquals("First Step", breakdown[0].name)
        assertEquals(75.0, breakdown[0].units, 0.001)
        assertEquals(5.26, breakdown[0].rate, 0.001)
        assertEquals(394.50, breakdown[0].cost, 0.001)

        // Second Step: 25 kWh @ 8.50 = 212.50
        assertEquals("Second Step", breakdown[1].name)
        assertEquals(25.0, breakdown[1].units, 0.001)
        assertEquals(8.50, breakdown[1].rate, 0.001)
        assertEquals(212.50, breakdown[1].cost, 0.001)
    }
}
