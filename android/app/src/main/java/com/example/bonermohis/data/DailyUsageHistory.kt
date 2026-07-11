package com.example.bonermohis.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.PrimaryKey

@Entity(
    tableName = "daily_usage_history",
    foreignKeys = [
        ForeignKey(
            entity = Account::class,
            parentColumns = ["id"],
            childColumns = ["account_id"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class DailyUsageHistory(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    @ColumnInfo(name = "account_id", index = true) val accountId: Int,
    @ColumnInfo(name = "date_epoch") val dateEpoch: Long,
    @ColumnInfo(name = "consumption_kwh") val consumptionKwh: Double,
    val cost: Double
)
