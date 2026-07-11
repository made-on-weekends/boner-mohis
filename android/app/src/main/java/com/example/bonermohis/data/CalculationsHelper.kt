package com.example.bonermohis.data

import kotlin.math.max
import kotlin.math.min

data class Slab(val limit: Double, val rate: Double)

data class SlabBreakdownLine(
    val name: String,
    val units: Double,
    val rate: Double,
    val cost: Double
)

data class SlabDetails(
    val index: Int,
    val rate: Double,
    val slabMin: Double,
    val slabMax: Double,
    val percentage: Double,
    val label: String
)

data class DistributorConfig(
    val name: String,
    val currency: String,
    val slabs: List<Slab>
)

object CalculationsHelper {
    
    fun getSlabBreakdown(kwh: Double, provider: String = "default"): List<SlabBreakdownLine> {
        val config = DISTRIBUTORS[provider] ?: DISTRIBUTORS["default"]!!
        var remaining = kwh
        val lines = mutableListOf<SlabBreakdownLine>()

        val isLifeline = kwh <= 50.0
        val startIdx = if (isLifeline) 0 else 1
        var prevLimit = 0.0

        val slabNames = listOf(
            "Lifeline", "First Step", "Second Step", "Third Step", 
            "Fourth Step", "Fifth Step", "Sixth Step"
        )

        for (i in startIdx until config.slabs.size) {
            val slab = config.slabs[i]
            val rangeWidth = slab.limit - prevLimit
            val units = min(remaining, rangeWidth)

            if (units > 0.0) {
                val cost = units * slab.rate
                val name = slabNames.getOrNull(i) ?: "Slab ${i + 1}"
                lines.add(
                    SlabBreakdownLine(
                        name = name,
                        units = Math.round(units * 100.0) / 100.0,
                        rate = slab.rate,
                        cost = Math.round(cost * 100.0) / 100.0
                    )
                )
            }

            remaining -= units
            prevLimit = slab.limit
            if (remaining <= 0.0) break
        }

        return lines
    }

    val DISTRIBUTORS = mapOf(
        "default" to DistributorConfig(
            name = "Standard Progressive Utility",
            currency = "৳",
            slabs = listOf(
                Slab(50.0, 4.63),
                Slab(75.0, 5.26),
                Slab(200.0, 8.50),
                Slab(300.0, 9.10),
                Slab(400.0, 9.62),
                Slab(600.0, 15.01),
                Slab(Double.POSITIVE_INFINITY, 17.35)
            )
        ),
        "dpdc" to DistributorConfig(
            name = "DPDC (Dhaka Power)",
            currency = "৳",
            slabs = listOf(
                Slab(50.0, 4.63),
                Slab(75.0, 5.26),
                Slab(200.0, 8.50),
                Slab(300.0, 9.10),
                Slab(400.0, 9.62),
                Slab(600.0, 15.01),
                Slab(Double.POSITIVE_INFINITY, 17.35)
            )
        ),
        "desco" to DistributorConfig(
            name = "DESCO (Dhaka Electric)",
            currency = "৳",
            slabs = listOf(
                Slab(50.0, 4.63),
                Slab(75.0, 5.26),
                Slab(200.0, 8.50),
                Slab(300.0, 9.10),
                Slab(400.0, 9.62),
                Slab(600.0, 15.01),
                Slab(Double.POSITIVE_INFINITY, 17.35)
            )
        )
    )

    fun calculateCost(kwh: Double, provider: String = "default"): Double {
        val config = DISTRIBUTORS[provider] ?: DISTRIBUTORS["default"]!!
        var remaining = kwh
        var totalCost = 0.0
        
        val isLifeline = kwh <= 50.0
        val startIdx = if (isLifeline) 0 else 1
        var prevLimit = 0.0

        for (i in startIdx until config.slabs.size) {
            val slab = config.slabs[i]
            val rangeWidth = slab.limit - prevLimit
            val consumedInSlab = min(remaining, rangeWidth)
            totalCost += consumedInSlab * slab.rate
            remaining -= consumedInSlab
            prevLimit = slab.limit
            if (remaining <= 0.0) break
        }

        return Math.round(totalCost * 100.0) / 100.0
    }

    fun getSlabDetails(kwh: Double, provider: String = "default"): SlabDetails {
        val config = DISTRIBUTORS[provider] ?: DISTRIBUTORS["default"]!!
        
        // Find which slab index the current kwh falls into
        var index = 0
        for (i in config.slabs.indices) {
            if (kwh <= config.slabs[i].limit || config.slabs[i].limit == Double.POSITIVE_INFINITY) {
                index = i
                break
            }
        }

        val slab = config.slabs[index]

        data class SlabRange(val name: String, val min: Double, val max: Double)
        val slabRanges = listOf(
            SlabRange("Lifeline", 0.0, 50.0),
            SlabRange("First Step", if (kwh > 50.0) 0.0 else 51.0, 75.0),
            SlabRange("Second Step", 76.0, 200.0),
            SlabRange("Third Step", 201.0, 300.0),
            SlabRange("Fourth Step", 301.0, 400.0),
            SlabRange("Fifth Step", 401.0, 600.0),
            SlabRange("Sixth Step", 601.0, Double.POSITIVE_INFINITY)
        )

        val rangeConfig = slabRanges.getOrElse(index) {
            SlabRange("Slab ${index + 1}", 0.0, slab.limit)
        }

        val slabMin = rangeConfig.min
        val slabMax = rangeConfig.max
        val rangeWidth = slabMax - slabMin

        val percentage = if (rangeWidth == Double.POSITIVE_INFINITY) {
            100.0
        } else {
            min(100.0, max(0.0, ((kwh - slabMin) / rangeWidth) * 100.0))
        }

        val label = if (slabMax == Double.POSITIVE_INFINITY) {
            "${rangeConfig.name} (> ${(slabMin - 1).toInt()} kWh)"
        } else {
            "${rangeConfig.name} (${slabMin.toInt()}-${slabMax.toInt()} kWh)"
        }

        return SlabDetails(
            index = index,
            rate = slab.rate,
            slabMin = slabMin,
            slabMax = slabMax,
            percentage = Math.round(percentage * 10.0) / 10.0,
            label = label
        )
    }

    fun calculateDaysRemaining(balance: Double, yesterdayUsage: Double): Double {
        if (yesterdayUsage <= 0.0) return Double.POSITIVE_INFINITY
        return Math.round((balance / yesterdayUsage) * 10.0) / 10.0
    }
}
