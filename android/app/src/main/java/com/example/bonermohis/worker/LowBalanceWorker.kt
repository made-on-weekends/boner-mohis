package com.example.bonermohis.worker

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.bonermohis.AppApplication
import com.example.bonermohis.MainActivity
import com.example.bonermohis.data.AppDatabase
import com.example.bonermohis.data.CalculationsHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

class LowBalanceWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val database = AppDatabase.getDatabase(applicationContext, CoroutineScope(SupervisorJob() + Dispatchers.Default))
        val accountDao = database.accountDao()
        
        val accounts = accountDao.getAll()
        var notificationsSent = 0

        val repository = (applicationContext as? AppApplication)?.repository
        for (account in accounts) {
            if (account.distributor == "desco" && repository != null) {
                try {
                    repository.syncAccount(account.id)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            
            val freshAccount = accountDao.getById(account.id) ?: account
            val daysRem = CalculationsHelper.calculateDaysRemaining(freshAccount.balance, freshAccount.yesterdayUsage)
            
            // Trigger alerts for accounts that will expire in under 2 days
            if (daysRem <= 2.0 && freshAccount.yesterdayUsage > 0.0) {
                sendNotification(freshAccount.id, freshAccount.nickname, daysRem, freshAccount.balance)
                notificationsSent++
            }
        }

        return Result.success()
    }

    private fun sendNotification(accountId: Int, nickname: String, daysRemaining: Double, balance: Double) {
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext, 
            accountId, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val formattedDays = String.format("%.1f", daysRemaining)
        val formattedBalance = String.format("%.2f", balance)

        val builder = NotificationCompat.Builder(applicationContext, AppApplication.CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning) // Android system warning icon
            .setContentTitle("⚠️ Low Electricity Balance!")
            .setContentText("'$nickname' will run out of balance in $formattedDays days (Current: ৳$formattedBalance).")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(applicationContext)) {
            // Check POST_NOTIFICATIONS permission on Android 13+ (API 33+)
            if (ActivityCompat.checkSelfPermission(
                    applicationContext,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                notify(accountId, builder.build())
            }
        }
    }
}
