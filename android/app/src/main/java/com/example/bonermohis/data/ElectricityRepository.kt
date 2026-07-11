package com.example.bonermohis.data

import kotlinx.coroutines.flow.Flow
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.random.Random

class ElectricityRepository(
    private val accountDao: AccountDao,
    private val dailyUsageDao: DailyUsageDao
) {
    val allAccounts: Flow<List<Account>> = accountDao.getAllFlow()

    fun getHistoryFlow(accountId: Int): Flow<List<DailyUsageHistory>> {
        return dailyUsageDao.getHistoryForAccountFlow(accountId)
    }

    suspend fun insertAccount(account: Account): Long {
        return accountDao.insert(account)
    }

    suspend fun deleteAccount(accountId: Int) {
        val account = accountDao.getById(accountId)
        if (account != null) {
            dailyUsageDao.deleteHistoryForAccount(accountId)
            accountDao.delete(account)
        }
    }

    suspend fun topUp(accountId: Int, amount: Double) {
        val account = accountDao.getById(accountId) ?: return
        val newBalance = account.balance + amount
        val updated = account.copy(
            balance = newBalance,
            lastUpdated = System.currentTimeMillis()
        )
        accountDao.update(updated)
    }

    suspend fun resetCycle(accountId: Int) {
        val account = accountDao.getById(accountId) ?: return
        val updated = account.copy(
            monthlyKwh = 0.0,
            currentSlab = 0,
            slabUsage = 0.0,
            lastUpdated = System.currentTimeMillis()
        )
        accountDao.update(updated)
    }

    suspend fun simulateDay(accountId: Int, customKwh: Double? = null) {
        val account = accountDao.getById(accountId) ?: return
        
        // 1. Generate usage
        val kwhUsed = customKwh ?: (4.0 + Random.nextDouble() * 8.0)
        
        // 2. Add to monthly total usage
        val oldMonthlyKwh = account.monthlyKwh
        val newMonthlyKwh = oldMonthlyKwh + kwhUsed
        
        // 3. Compute cost
        val costOfNewTotal = CalculationsHelper.calculateCost(newMonthlyKwh, account.distributor)
        val costOfOldTotal = CalculationsHelper.calculateCost(oldMonthlyKwh, account.distributor)
        val dailyCost = maxOf(0.0, costOfNewTotal - costOfOldTotal)
        
        // 4. Deduct cost from balance
        val newBalance = maxOf(0.0, account.balance - dailyCost)
        
        // 5. Determine active slab tier stats
        val slabStats = CalculationsHelper.getSlabDetails(newMonthlyKwh, account.distributor)
        
        // 6. Write daily history record
        dailyUsageDao.insert(
            DailyUsageHistory(
                accountId = accountId,
                dateEpoch = System.currentTimeMillis(),
                consumptionKwh = kwhUsed,
                cost = dailyCost
            )
        )
        
        // 7. Update account metrics
        val updated = account.copy(
            balance = newBalance,
            monthlyKwh = newMonthlyKwh,
            yesterdayUsage = dailyCost,
            currentSlab = slabStats.index,
            slabUsage = newMonthlyKwh - slabStats.slabMin,
            lastUpdated = System.currentTimeMillis()
        )
        
        accountDao.update(updated)
    }

    suspend fun syncAccount(accountId: Int) = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
        val account = accountDao.getById(accountId) ?: return@withContext
        if (account.distributor != "desco") return@withContext

        try {
            // 1. Fetch balance
            val balanceUrl = "https://prepaid.desco.org.bd/api/tkdes/customer/getBalance?accountNo=${account.accountNo}&meterNo=${account.meterNo}"
            val balanceRes = httpGet(balanceUrl) ?: throw Exception("Failed to fetch DESCO balance")
            val balanceObj = org.json.JSONObject(balanceRes)
            if (balanceObj.getInt("code") != 200) throw Exception(balanceObj.optString("desc", "DESCO error"))
            
            val data = balanceObj.getJSONObject("data")
            val liveBalance = data.getDouble("balance")
            // NOTE: currentMonthConsumption is BDT cost, NOT kWh.
            // The actual kWh is derived from consumedUnit in the daily consumption endpoint below.
            var liveMonthlyKwh = 0.0

            // 2. Fetch daily consumption for last 15 days
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val dateTo = sdf.format(Date())
            val cal = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -15) }
            val dateFrom = sdf.format(cal.time)

            val consumptionUrl = "https://prepaid.desco.org.bd/api/tkdes/customer/getCustomerDailyConsumption?accountNo=${account.accountNo}&meterNo=${account.meterNo}&dateFrom=$dateFrom&dateTo=$dateTo"
            val consumptionRes = httpGet(consumptionUrl)
            var yesterdayCost = account.yesterdayUsage

            if (consumptionRes != null) {
                val consumptionObj = org.json.JSONObject(consumptionRes)
                if (consumptionObj.getInt("code") == 200) {
                    val dataArray = consumptionObj.getJSONArray("data")
                    val list = mutableListOf<org.json.JSONObject>()
                    for (i in 0 until dataArray.length()) {
                        list.add(dataArray.getJSONObject(i))
                    }
                    
                    list.sortBy { it.getString("date") }
                    
                    // Derive monthly kWh from consumedUnit (cumulative all-time meter reading).
                    // consumedTaka resets at month boundary; consumedUnit never resets.
                    // Base must be the LAST entry from the PREVIOUS month so that the
                    // first day of the current month is included in the delta.
                    if (list.isNotEmpty()) {
                        val latestEntry = list.last()
                        val currentMonthStr = latestEntry.getString("date").substring(0, 7) // "yyyy-MM"
                        val lastOfPrevMonth = list.lastOrNull { !it.getString("date").startsWith(currentMonthStr) }
                        val baseUnit = lastOfPrevMonth?.getDouble("consumedUnit")
                            ?: list.firstOrNull { it.getString("date").startsWith(currentMonthStr) }?.getDouble("consumedUnit")
                            ?: latestEntry.getDouble("consumedUnit")
                        liveMonthlyKwh = maxOf(0.0, latestEntry.getDouble("consumedUnit") - baseUnit)
                        liveMonthlyKwh = Math.round(liveMonthlyKwh * 1000) / 1000.0
                    }
                    
                    for (i in 0 until list.size) {
                        val current = list[i]
                        val prev = if (i > 0) list[i - 1] else null
                        
                        var dailyKwh = 0.0
                        var dailyCost = 0.0
                        
                        if (prev != null) {
                            dailyKwh = current.getDouble("consumedUnit") - prev.getDouble("consumedUnit")
                            
                            val currentMonth = current.getString("date").split("-")[1]
                            val prevMonth = prev.getString("date").split("-")[1]
                            if (currentMonth == prevMonth) {
                                dailyCost = maxOf(0.0, current.getDouble("consumedTaka") - prev.getDouble("consumedTaka"))
                            } else {
                                dailyCost = current.getDouble("consumedTaka")
                            }
                        }

                        if (dailyKwh > 0.0 || dailyCost > 0.0) {
                            val dateEpoch = sdf.parse(current.getString("date"))?.time ?: System.currentTimeMillis()
                            val existing = dailyUsageDao.getRecordForDay(accountId, dateEpoch)
                            if (existing != null) {
                                dailyUsageDao.update(existing.copy(consumptionKwh = dailyKwh, cost = dailyCost))
                            } else {
                                dailyUsageDao.insert(
                                    DailyUsageHistory(
                                        accountId = accountId,
                                        dateEpoch = dateEpoch,
                                        consumptionKwh = dailyKwh,
                                        cost = dailyCost
                                    )
                                )
                            }
                        }
                    }

                    if (list.size >= 2) {
                        val last = list[list.size - 1]
                        val secLast = list[list.size - 2]
                        val lastMonth = last.getString("date").split("-")[1]
                        val secLastMonth = secLast.getString("date").split("-")[1]
                        if (lastMonth == secLastMonth) {
                            yesterdayCost = maxOf(0.0, last.getDouble("consumedTaka") - secLast.getDouble("consumedTaka"))
                        } else {
                            yesterdayCost = last.getDouble("consumedTaka")
                        }
                    }
                }
            }

            // 3. Compute active slab details
            val slabStats = CalculationsHelper.getSlabDetails(liveMonthlyKwh, "desco")

            // 4. Update and save account
            val updated = account.copy(
                balance = liveBalance,
                monthlyKwh = liveMonthlyKwh,
                yesterdayUsage = yesterdayCost,
                currentSlab = slabStats.index,
                slabUsage = liveMonthlyKwh - slabStats.slabMin,
                lastUpdated = System.currentTimeMillis()
            )
            accountDao.update(updated)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun httpGet(urlString: String): String? {
        var connection: java.net.HttpURLConnection? = null
        return try {
            val url = java.net.URL(urlString)
            connection = url.openConnection() as java.net.HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        } finally {
            connection?.disconnect()
        }
    }
}
