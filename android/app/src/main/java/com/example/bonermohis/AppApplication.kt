package com.example.bonermohis

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.bonermohis.data.AppDatabase
import com.example.bonermohis.data.ElectricityRepository
import com.example.bonermohis.worker.LowBalanceWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.util.Calendar
import java.util.concurrent.TimeUnit

class AppApplication : Application() {

    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val database by lazy { AppDatabase.getDatabase(this, applicationScope) }
    val repository by lazy { ElectricityRepository(database.accountDao(), database.dailyUsageDao()) }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupBackgroundWorker()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Low Balance Alerts"
            val descriptionText = "Notifications for prepaid accounts that will run out of balance in under 2 days."
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun setupBackgroundWorker() {
        val currentDate = Calendar.getInstance()
        val dueDate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 6)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
        }

        if (dueDate.before(currentDate)) {
            dueDate.add(Calendar.HOUR_OF_DAY, 24)
        }

        val timeDiff = dueDate.timeInMillis - currentDate.timeInMillis

        val workRequest = PeriodicWorkRequestBuilder<LowBalanceWorker>(
            24, TimeUnit.HOURS
        )
        .setInitialDelay(timeDiff, TimeUnit.MILLISECONDS)
        .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "low_balance_checker",
            ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )
    }

    companion object {
        const val CHANNEL_ID = "low_balance_alerts"
    }
}
