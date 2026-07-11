package com.example.bonermohis.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface DailyUsageDao {
    @Query("SELECT * FROM daily_usage_history WHERE account_id = :accountId ORDER BY date_epoch DESC LIMIT 60")
    fun getHistoryForAccountFlow(accountId: Int): kotlinx.coroutines.flow.Flow<List<DailyUsageHistory>>

    @Query("SELECT * FROM daily_usage_history WHERE account_id = :accountId ORDER BY date_epoch DESC LIMIT 60")
    suspend fun getHistoryForAccount(accountId: Int): List<DailyUsageHistory>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(history: DailyUsageHistory)

    @androidx.room.Update
    suspend fun update(history: DailyUsageHistory)

    @Query("SELECT * FROM daily_usage_history WHERE account_id = :accountId AND date_epoch = :dateEpoch LIMIT 1")
    suspend fun getRecordForDay(accountId: Int, dateEpoch: Long): DailyUsageHistory?

    @Query("DELETE FROM daily_usage_history WHERE account_id = :accountId")
    suspend fun deleteHistoryForAccount(accountId: Int)
}
