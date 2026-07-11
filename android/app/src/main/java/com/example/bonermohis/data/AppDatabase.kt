package com.example.bonermohis.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(entities = [Account::class, DailyUsageHistory::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun accountDao(): AccountDao
    abstract fun dailyUsageDao(): DailyUsageDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context, scope: CoroutineScope): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "boner_mohis_database"
                )
                .addCallback(AppDatabaseCallback(scope))
                .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class AppDatabaseCallback(
        private val scope: CoroutineScope
    ) : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            INSTANCE?.let { database ->
                scope.launch(Dispatchers.IO) {
                    populateDatabase(database.accountDao(), database.dailyUsageDao())
                }
            }
        }

        suspend fun populateDatabase(accountDao: AccountDao, dailyUsageDao: DailyUsageDao) {
            // Seed Account 1
            val acc1Id = accountDao.insert(
                Account(
                    nickname = "Main Home",
                    distributor = "dpdc",
                    accountNo = "20948572",
                    meterNo = "90082731",
                    balance = 1450.00,
                    lastUpdated = System.currentTimeMillis(),
                    currentSlab = 2,
                    slabUsage = 45.5,
                    yesterdayUsage = 48.50,
                    monthlyKwh = 120.5
                )
            ).toInt()

            val now = System.currentTimeMillis()
            val oneDayMs = 24 * 60 * 60 * 1000L
            
            // Seed history for Account 1 (monthlyKwh=120.5, currently in Second Step)
            // Simulates progressive tariff transitions across 7 days:
            // Day -7: cumul ~71.5 kWh → fully in First Step (6.18 rate)
            // Day -6: cumul ~78.5 kWh → CROSSES into Second Step (blended 7.34 rate)
            // Day -5 to -1: fully in Second Step (8.50 rate)
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - oneDayMs, consumptionKwh = 12.0, cost = 102.00))       // rate=8.50
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 2 * oneDayMs, consumptionKwh = 7.0, cost = 59.50))    // rate=8.50
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 3 * oneDayMs, consumptionKwh = 8.5, cost = 72.25))    // rate=8.50
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 4 * oneDayMs, consumptionKwh = 7.0, cost = 59.50))    // rate=8.50
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 5 * oneDayMs, consumptionKwh = 7.5, cost = 63.75))    // rate=8.50
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 6 * oneDayMs, consumptionKwh = 7.0, cost = 51.38))    // rate=7.34 (crosses 75 boundary)
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc1Id, dateEpoch = now - 7 * oneDayMs, consumptionKwh = 7.0, cost = 43.26))    // rate=6.18

            // Seed Account 2
            val acc2Id = accountDao.insert(
                Account(
                    nickname = "Guest Cottage",
                    distributor = "desco",
                    accountNo = "77635291",
                    meterNo = "44526178",
                    balance = 65.50, // Low balance! (Will run out in ~1.5 days based on 42.0 yesterday usage)
                    lastUpdated = System.currentTimeMillis() - 3600000L,
                    currentSlab = 1,
                    slabUsage = 14.2,
                    yesterdayUsage = 42.00,
                    monthlyKwh = 64.2
                )
            ).toInt()

            // Seed history for Account 2 (monthlyKwh=64.2, in First Step)
            // Simulates crossing the Lifeline→First Step boundary at 50 kWh:
            // Day -7 to -4: in Lifeline (5.32 rate)
            // Day -3: CROSSES into First Step (blended 5.40 rate)
            // Day -2 to -1: fully in First Step (6.18 rate)
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - oneDayMs, consumptionKwh = 6.5, cost = 40.17))        // rate=6.18
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 2 * oneDayMs, consumptionKwh = 7.0, cost = 43.26))    // rate=6.18
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 3 * oneDayMs, consumptionKwh = 7.5, cost = 40.51))    // rate=5.40 (crosses 50 boundary)
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 4 * oneDayMs, consumptionKwh = 8.0, cost = 42.56))    // rate=5.32
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 5 * oneDayMs, consumptionKwh = 7.0, cost = 37.24))    // rate=5.32
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 6 * oneDayMs, consumptionKwh = 6.0, cost = 31.92))    // rate=5.32
            dailyUsageDao.insert(DailyUsageHistory(accountId = acc2Id, dateEpoch = now - 7 * oneDayMs, consumptionKwh = 6.0, cost = 31.92))    // rate=5.32
        }
    }
}
