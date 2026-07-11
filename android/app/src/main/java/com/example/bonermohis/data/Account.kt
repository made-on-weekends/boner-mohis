package com.example.bonermohis.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "accounts")
data class Account(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val nickname: String,
    val distributor: String,
    val accountNo: String,
    val meterNo: String,
    val balance: Double,
    val lastUpdated: Long,
    val currentSlab: Int,
    val slabUsage: Double,
    val yesterdayUsage: Double,
    val monthlyKwh: Double
)
