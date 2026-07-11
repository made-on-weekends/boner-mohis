package com.example.bonermohis.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.foundation.Canvas
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.toArgb
import android.graphics.Paint
import android.graphics.Rect
import com.example.bonermohis.data.Account
import com.example.bonermohis.data.CalculationsHelper
import com.example.bonermohis.data.DailyUsageHistory
import com.example.bonermohis.theme.*
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun ChargeBar(monthlyKwh: Double, loading: Boolean = false) {
    val tierRanges = listOf(
        Pair(0.0, 50.0) to (50.0 / 600.0),
        Pair(50.0, 75.0) to (25.0 / 600.0),
        Pair(75.0, 200.0) to (125.0 / 600.0),
        Pair(200.0, 300.0) to (100.0 / 600.0),
        Pair(300.0, 400.0) to (100.0 / 600.0),
        Pair(400.0, 600.0) to (200.0 / 600.0)
    )

    fun getColorForKwh(valKwh: Double): Color {
        val clamped = valKwh.coerceIn(0.0, 600.0)
        return if (clamped <= 300.0) {
            val ratio = (clamped / 300.0).toFloat()
            Color(
                red = 0x2E / 255f + (0xB2 / 255f - 0x2E / 255f) * ratio,
                green = 0x7D / 255f + (0x54 / 255f - 0x7D / 255f) * ratio,
                blue = 0x3A / 255f + (0x09 / 255f - 0x3A / 255f) * ratio
            )
        } else {
            val ratio = ((clamped - 300.0) / 300.0).toFloat()
            Color(
                red = 0xB2 / 255f + (0xC2 / 255f - 0xB2 / 255f) * ratio,
                green = 0x54 / 255f + (0x2A / 255f - 0x54 / 255f) * ratio,
                blue = 0x09 / 255f + (0x21 / 255f - 0x09 / 255f) * ratio
            )
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(8.dp),
        horizontalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        tierRanges.forEach { (range, weight) ->
            val minVal = range.first
            val maxVal = range.second
            val rangeWidth = maxVal - minVal
            val consumed = (monthlyKwh - minVal).coerceIn(0.0, rangeWidth)
            val fillFraction = if (loading) 0f else (consumed / rangeWidth).toFloat()

            val startColor = getColorForKwh(minVal)
            val endColor = getColorForKwh(maxVal)

            Box(
                modifier = Modifier
                    .weight(weight.toFloat())
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(2.dp))
                    .background(MaterialTheme.colorScheme.onBackground.copy(alpha = 0.07f))
            ) {
                if (fillFraction > 0f) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(fraction = fillFraction)
                            .background(
                                brush = Brush.horizontalGradient(
                                    colors = listOf(startColor, endColor)
                                )
                            )
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel,
    modifier: Modifier = Modifier
) {
    val accounts by viewModel.accounts.collectAsStateWithLifecycle()
    val selectedId by viewModel.selectedAccountId.collectAsStateWithLifecycle()
    val historyLogs by viewModel.selectedAccountHistory.collectAsStateWithLifecycle()

    var showAddDialog by remember { mutableStateOf(false) }
    var showDropdown by remember { mutableStateOf(false) }

    // Auto-select first account if selection is null and list is populated
    LaunchedEffect(accounts) {
        if (selectedId == null && accounts.isNotEmpty()) {
            viewModel.selectAccount(accounts.first().id)
        }
    }

    val selectedAccount = accounts.find { it.id == selectedId }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "Boner Mohis",
                            fontSize = 24.sp,
                            fontFamily = SpaceGroteskFontFamily,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onBackground,
                            letterSpacing = (-0.5).sp
                        )
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(2.dp),
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Box(modifier = Modifier.size(6.dp, 12.dp).background(MaterialTheme.colorScheme.onBackground, RoundedCornerShape(1.dp)))
                            Box(modifier = Modifier.size(6.dp, 12.dp).background(MaterialTheme.colorScheme.onBackground, RoundedCornerShape(1.dp)))
                            Box(modifier = Modifier.size(6.dp, 12.dp).background(EmberOrange, RoundedCornerShape(1.dp)))
                        }
                    }
                    Text(
                        text = "Prepaid Electricity Meter Genius",
                        fontSize = 12.sp,
                        fontFamily = DmSansFontFamily,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                    )
                }
                IconButton(
                    onClick = { showAddDialog = true },
                    colors = IconButtonDefaults.iconButtonColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.onBackground
                    ),
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add account",
                        tint = MaterialTheme.colorScheme.onBackground
                    )
                }
            }

            if (selectedAccount == null) {
                // Empty state
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No accounts added yet.\nClick '+' to add your first electricity account.",
                        textAlign = TextAlign.Center,
                        fontFamily = DmSansFontFamily,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        fontSize = 14.sp
                    )
                }
            } else {
                // Account Selector Dropdown trigger
                Box(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.surface)
                            .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                            .clickable { showDropdown = true }
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${selectedAccount.nickname} (${selectedAccount.accountNo})",
                            color = MaterialTheme.colorScheme.onSurface,
                            fontFamily = DmSansFontFamily,
                            fontWeight = FontWeight.Medium,
                            fontSize = 14.sp
                        )
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = "Open account list",
                            tint = MaterialTheme.colorScheme.onSurface
                        )
                    }

                    DropdownMenu(
                        expanded = showDropdown,
                        onDismissRequest = { showDropdown = false },
                        modifier = Modifier
                            .fillMaxWidth(0.9f)
                            .background(MaterialTheme.colorScheme.surface)
                            .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                    ) {
                        accounts.forEach { acc ->
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        text = "${acc.nickname} (${acc.accountNo})",
                                        color = MaterialTheme.colorScheme.onSurface,
                                        fontFamily = DmSansFontFamily
                                    )
                                },
                                onClick = {
                                    viewModel.selectAccount(acc.id)
                                    showDropdown = false
                                }
                            )
                        }
                    }
                }

                // Dashboard Main Card
                DashboardCard(
                    account = selectedAccount,
                    history = historyLogs,
                    onSimulate = { 
                        if (selectedAccount.distributor == "desco") {
                            viewModel.syncLive()
                        } else {
                            viewModel.simulateDay()
                        }
                    },
                    onReset = { viewModel.resetCycle() },
                    onTopUp = { amount -> viewModel.topUp(amount) },
                    onDelete = { viewModel.deleteAccount() }
                )
            }
        }

        // Add Account Dialog Modal
        if (showAddDialog) {
            AddAccountDialog(
                onDismiss = { showAddDialog = false },
                onAdd = { nickname, provider, accountNo, meterNo, balance, monthlyKwh ->
                    viewModel.addAccount(nickname, provider, accountNo, meterNo, balance, monthlyKwh)
                    showAddDialog = false
                }
            )
        }
    }
}

@Composable
fun DashboardCard(
    account: Account,
    history: List<DailyUsageHistory>,
    onSimulate: () -> Unit,
    onReset: () -> Unit,
    onTopUp: (Double) -> Unit,
    onDelete: () -> Unit
) {
    var topUpAmountStr by remember { mutableStateOf("") }
    val daysRemaining = CalculationsHelper.calculateDaysRemaining(account.balance, account.yesterdayUsage)
    val isLowBalance = daysRemaining <= 2.0 && account.yesterdayUsage > 0.0

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Low Balance Alert
        if (isLowBalance) {
            val rate = CalculationsHelper.getSlabDetails(account.monthlyKwh, account.distributor).rate
            val remainingUnits = if (rate > 0.0) Math.round(account.balance / rate) else 0L
            val dateFormatted = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(account.lastUpdated)).lowercase(Locale.getDefault())

            item {
                Surface(
                    color = StateCritical.copy(alpha = 0.08f),
                    border = BorderStroke(1.dp, StateCritical.copy(alpha = 0.5f)),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = null,
                            tint = StateCritical,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = "Home meter · $remainingUnits units · ~$daysRemaining days left at your usual usage (estimate) · as of $dateFormatted, manual entry",
                            color = MaterialTheme.colorScheme.onBackground,
                            fontSize = 12.sp,
                            fontFamily = DmSansFontFamily,
                            fontWeight = FontWeight.Normal
                        )
                    }
                }
            }
        }

        // Account Header Meta & Delete Button
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = account.nickname,
                        fontSize = 20.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    Text(
                        text = "A/C · ${account.accountNo}",
                        fontSize = 12.sp,
                        fontFamily = DmMonoFontFamily,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f),
                        letterSpacing = 0.3.sp
                    )
                    Surface(
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = account.distributor.uppercase(Locale.ROOT),
                            color = MaterialTheme.colorScheme.primary,
                            fontSize = 9.sp,
                            fontFamily = DmMonoFontFamily,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            letterSpacing = 0.5.sp
                        )
                    }
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete Account",
                        tint = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                    )
                }
            }
        }

        // Balance Display
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(vertical = 20.dp, horizontal = 4.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Accent top pip
                Box(
                    modifier = Modifier
                        .width(32.dp)
                        .height(3.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.4f))
                )
                Spacer(modifier = Modifier.height(14.dp))
                Row(
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "৳",
                        fontSize = 24.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(bottom = 6.dp, end = 4.dp)
                    )
                    Text(
                        text = String.format(Locale.US, "%,.2f", account.balance),
                        fontSize = 52.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onBackground,
                        letterSpacing = (-1.5).sp
                    )
                }
                Spacer(modifier = Modifier.height(10.dp))
                Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp)) {
                    ChargeBar(monthlyKwh = account.monthlyKwh)
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = "REMAINING BALANCE",
                    fontSize = 10.sp,
                    fontFamily = DmSansFontFamily,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.45f),
                    letterSpacing = 1.sp
                )
            }
        }


        // Detail Info Grid: 7 cards in 2 rows
        item {
            val maxLoadLastMonth = if (history.isNotEmpty()) {
                history.maxOf { it.consumptionKwh } / 10.0
            } else { 0.0 }
            val maxLoadText = if (history.isNotEmpty()) {
                String.format(Locale.US, "%.2f kW", maxLoadLastMonth)
            } else { "-- kW" }

            val daysElapsed    = (history.size).coerceAtLeast(1)
            val dailyAvgKwh   = account.monthlyKwh / daysElapsed
            val calendar      = java.util.Calendar.getInstance()
            val dayOfMonth    = calendar.get(java.util.Calendar.DAY_OF_MONTH)
            val daysInMonth   = calendar.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)
            // yesterday is the last full day we have data for, so remaining = daysInMonth - (dayOfMonth - 1)
            val daysRemaining = (daysInMonth - (dayOfMonth - 1)).coerceAtLeast(0)
            val projectedKwh  = (account.monthlyKwh + dailyAvgKwh * daysRemaining).coerceAtMost(9999.0)
            val spendThisMonth = CalculationsHelper.calculateCost(account.monthlyKwh, account.distributor)
            val forecastBill   = CalculationsHelper.calculateCost(projectedKwh, account.distributor)
            val yesterdayBill = account.yesterdayUsage

            var showBillBreakdownDialog by remember { mutableStateOf(false) }
            var showConsumptionBreakdownDialog by remember { mutableStateOf(false) }

            @Composable
            fun RowScope.MiniCard(
                label: String,
                value: String,
                highlight: Boolean = false,
                isLow: Boolean = false,
                onClick: (() -> Unit)? = null
            ) {
                val cardBg = when {
                    highlight && isLow -> StateCritical.copy(alpha = 0.06f)
                    highlight -> StateOk.copy(alpha = 0.06f)
                    else -> MaterialTheme.colorScheme.surface
                }
                val cardBorder = when {
                    highlight && isLow -> StateCritical
                    highlight -> StateOk
                    else -> MaterialTheme.colorScheme.outline
                }
                val valueColor = when {
                    highlight && isLow -> StateCritical
                    highlight -> StateOk
                    else -> MaterialTheme.colorScheme.onBackground
                }
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
                    color = cardBg,
                    border = BorderStroke(1.dp, cardBorder),
                    shape = RoundedCornerShape(12.dp),
                    tonalElevation = 1.dp
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 6.dp, vertical = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Text(
                                text = label,
                                fontSize = 9.sp,
                                fontFamily = DmSansFontFamily,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f),
                                letterSpacing = 0.2.sp,
                                maxLines = 2,
                                textAlign = TextAlign.Center
                            )
                            if (onClick != null) {
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .background(
                                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                                            shape = RoundedCornerShape(5.dp)
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "i",
                                        fontSize = 7.sp,
                                        fontFamily = DmMonoFontFamily,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        }
                        Text(
                            text = value,
                            fontSize = 16.sp,
                            fontFamily = DmMonoFontFamily,
                            fontWeight = FontWeight.Bold,
                            color = valueColor,
                            maxLines = 1,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                // Row 1: Spend, Consumed, Max Load, Yesterday Bill
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    MiniCard("SPEND THIS MONTH", "৳${String.format(Locale.US, "%.2f", spendThisMonth)}")
                    MiniCard("CONSUMED THIS MONTH", "${String.format(Locale.US, "%.0f", account.monthlyKwh)} kWh")
                    MiniCard("MAX LOAD LAST MONTH", maxLoadText)
                    MiniCard("YESTERDAY BILL", "৳${String.format(Locale.US, "%.2f", yesterdayBill)}")
                }
                // Row 2: Forecast Bill, Forecast Consumption, Forecast Remaining
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    MiniCard(
                        label = "FORECAST BILL",
                        value = "৳${String.format(Locale.US, "%.2f", forecastBill)}",
                        onClick = { showBillBreakdownDialog = true }
                    )
                    MiniCard(
                        label = "FORECAST CONSUMPTION",
                        value = "${String.format(Locale.US, "%.0f", projectedKwh)} kWh",
                        onClick = { showConsumptionBreakdownDialog = true }
                    )
                    MiniCard(
                        label = "FORECAST REMAINING",
                        value = if (account.yesterdayUsage <= 0.0)
                            "-- days" else "${daysRemaining} days",
                        highlight = true,
                        isLow = isLowBalance
                    )
                }
            }

            if (showBillBreakdownDialog) {
                AlertDialog(
                    onDismissRequest = { showBillBreakdownDialog = false },
                    confirmButton = {
                        TextButton(onClick = { showBillBreakdownDialog = false }) {
                            Text("Close", fontFamily = DmSansFontFamily)
                        }
                    },
                    title = {
                        Text(
                            "Forecasted Bill Breakdown",
                            fontFamily = SpaceGroteskFontFamily,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    },
                    text = {
                        val breakdown = CalculationsHelper.getSlabBreakdown(projectedKwh, account.distributor)
                        Column(
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
                        ) {
                            Text(
                                "Calculated progressively based on current BERC slabs for ${account.distributor.uppercase(Locale.ROOT)}.",
                                fontSize = 12.sp,
                                fontFamily = DmSansFontFamily,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Tier", modifier = Modifier.weight(1.5f), fontSize = 11.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                                Text("Units", modifier = Modifier.weight(1f), fontSize = 11.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                                Text("Rate", modifier = Modifier.weight(1f), fontSize = 11.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                                Text("Cost", modifier = Modifier.weight(1.2f), fontSize = 11.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f))
                            }
                            
                            HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))
                            
                            breakdown.forEach { line ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(line.name, modifier = Modifier.weight(1.5f), fontSize = 12.sp, fontFamily = DmSansFontFamily)
                                    Text("${line.units} kWh", modifier = Modifier.weight(1f), fontSize = 12.sp, fontFamily = DmMonoFontFamily, textAlign = TextAlign.End)
                                    Text("৳${String.format(Locale.US, "%.2f", line.rate)}", modifier = Modifier.weight(1f), fontSize = 12.sp, fontFamily = DmMonoFontFamily, textAlign = TextAlign.End)
                                    Text("৳${String.format(Locale.US, "%.2f", line.cost)}", modifier = Modifier.weight(1.2f), fontSize = 12.sp, fontFamily = DmMonoFontFamily, textAlign = TextAlign.End, fontWeight = FontWeight.Bold)
                                }
                            }
                            
                            HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Total", modifier = Modifier.weight(1.5f), fontSize = 13.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold)
                                Text("", modifier = Modifier.weight(2f))
                                Text("৳${String.format(Locale.US, "%.2f", forecastBill)}", modifier = Modifier.weight(1.2f), fontSize = 13.sp, fontFamily = DmMonoFontFamily, textAlign = TextAlign.End, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                            }
                        }
                    }
                )
            }

            if (showConsumptionBreakdownDialog) {
                AlertDialog(
                    onDismissRequest = { showConsumptionBreakdownDialog = false },
                    confirmButton = {
                        TextButton(onClick = { showConsumptionBreakdownDialog = false }) {
                            Text("Close", fontFamily = DmSansFontFamily)
                        }
                    },
                    title = {
                        Text(
                            "Forecasted Consumption Details",
                            fontFamily = SpaceGroteskFontFamily,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    },
                    text = {
                        Column(
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
                        ) {
                            Text(
                                "Formula: Consumed So Far + (Daily Average × Days Remaining)",
                                fontSize = 12.sp,
                                fontFamily = DmSansFontFamily,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Consumed so far", fontSize = 12.sp, fontFamily = DmSansFontFamily)
                                Text("${String.format(Locale.US, "%.1f", account.monthlyKwh)} kWh", fontSize = 12.sp, fontFamily = DmMonoFontFamily, fontWeight = FontWeight.Bold)
                            }
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Daily average", fontSize = 12.sp, fontFamily = DmSansFontFamily)
                                Text("${String.format(Locale.US, "%.2f", dailyAvgKwh)} kWh/day", fontSize = 12.sp, fontFamily = DmMonoFontFamily, fontWeight = FontWeight.Bold)
                            }
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Days remaining in month", fontSize = 12.sp, fontFamily = DmSansFontFamily)
                                Text("$daysRemaining days", fontSize = 12.sp, fontFamily = DmMonoFontFamily, fontWeight = FontWeight.Bold)
                            }
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Projected remainder", fontSize = 12.sp, fontFamily = DmSansFontFamily)
                                Text("${String.format(Locale.US, "%.1f", dailyAvgKwh * daysRemaining)} kWh", fontSize = 12.sp, fontFamily = DmMonoFontFamily, fontWeight = FontWeight.Bold)
                            }
                            
                            HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Forecast Total", fontSize = 13.sp, fontFamily = DmSansFontFamily, fontWeight = FontWeight.Bold)
                                Text("${String.format(Locale.US, "%.1f", projectedKwh)} kWh", fontSize = 13.sp, fontFamily = DmMonoFontFamily, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                            }
                        }
                    }
                )
            }
        }


        // Slab Visualizer
        item {
            val slabStats = CalculationsHelper.getSlabDetails(account.monthlyKwh, account.distributor)
            val fraction = (slabStats.percentage / 100.0).toFloat().coerceIn(0f, 1f)
            val markerBias = (fraction * 2f) - 1f
            
            Surface(
                color = MaterialTheme.colorScheme.surface,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Current billing tier", fontSize = 11.sp, fontFamily = DmSansFontFamily, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f))
                        Text(
                            text = slabStats.label,
                            fontSize = 12.sp,
                            fontFamily = DmSansFontFamily,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    // Progress bar with arrow marker
                    Box(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.fillMaxWidth()) {
                            // Arrow marker row
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(bottom = 2.dp)
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier.align(
                                        BiasAlignment(horizontalBias = markerBias, verticalBias = 0f)
                                    )
                                ) {
                                    Text(
                                        text = "${String.format(Locale.US, "%.1f", account.monthlyKwh)} kWh",
                                        fontSize = 10.sp,
                                        fontFamily = DmMonoFontFamily,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = "▼",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.primary,
                                        lineHeight = 12.sp
                                    )
                                }
                            }

                            // Gradient progress bar (green at 0% → red at 100% of slab)
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(8.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(MaterialTheme.colorScheme.onBackground.copy(alpha = 0.05f))
                            ) {
                                // Gradient fill sized to current percentage
                                if (fraction > 0f) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxHeight()
                                            .fillMaxWidth(fraction = fraction)
                                            .background(
                                                brush = Brush.linearGradient(
                                                    colorStops = arrayOf(
                                                        0.00f to Color(0xFF2E7D3A),
                                                        0.30f to Color(0xFF8F9B28),
                                                        0.65f to Color(0xFFB25409),
                                                        1.00f to Color(0xFFC22A21)
                                                    )
                                                )
                                            )
                                    )
                                }
                            }

                            // Range labels
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 2.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = "${slabStats.slabMin.toInt()} kWh",
                                    fontSize = 10.sp,
                                    fontFamily = DmMonoFontFamily,
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                                )
                                Text(
                                    text = if (slabStats.slabMax == Double.MAX_VALUE) "∞"
                                           else "${slabStats.slabMax.toInt()} kWh",
                                    fontSize = 10.sp,
                                    fontFamily = DmMonoFontFamily,
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                                )
                            }
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "${String.format(Locale.US, "%.2f", account.slabUsage)} kWh in tier",
                            fontSize = 11.sp,
                            fontFamily = DmSansFontFamily,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                        )
                        Text(
                            text = "${slabStats.percentage}% used",
                            fontSize = 11.sp,
                            fontFamily = DmSansFontFamily,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground
                        )
                    }
                }
            }
        }

        // Simulator Controls
        item {
            Surface(
                color = MaterialTheme.colorScheme.surface,
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    val isDesco = account.distributor == "desco"
                    Text(
                        text = if (isDesco) "LIVE API OPERATIONS" else "SIMULATOR CONTROLS",
                        fontSize = 12.sp,
                        fontFamily = DmSansFontFamily,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        letterSpacing = 0.5.sp
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = onSimulate,
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary,
                                contentColor = MaterialTheme.colorScheme.background
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = if (isDesco) Icons.Default.Refresh else Icons.Default.PlayArrow,
                                    contentDescription = null,
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = if (isDesco) "Sync Live" else "Simulate 24H",
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = DmSansFontFamily,
                                    fontSize = 12.sp
                                )
                            }
                        }
                        Button(
                            onClick = onReset,
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.05f),
                                contentColor = MaterialTheme.colorScheme.onBackground
                            ),
                            shape = RoundedCornerShape(12.dp),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Refresh,
                                    contentDescription = null,
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = "Reset Cycle",
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = DmSansFontFamily,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = topUpAmountStr,
                            onValueChange = { topUpAmountStr = it },
                            placeholder = { Text("Amount", fontSize = 12.sp, fontFamily = DmSansFontFamily, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                                focusedBorderColor = MaterialTheme.colorScheme.primary,
                                unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                                focusedContainerColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.02f),
                                unfocusedContainerColor = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.02f)
                            ),
                            shape = RoundedCornerShape(12.dp),
                            prefix = { Text("৳ ", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold, fontFamily = SpaceGroteskFontFamily) }
                        )

                        Button(
                            onClick = {
                                val amt = topUpAmountStr.toDoubleOrNull()
                                if (amt != null && amt > 0.0) {
                                    onTopUp(amt)
                                    topUpAmountStr = ""
                                }
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = EmberOrangePressed,
                                contentColor = MaterialTheme.colorScheme.background
                            ),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.height(48.dp)
                        ) {
                            Text("Top Up", fontWeight = FontWeight.Bold, fontFamily = DmSansFontFamily)
                        }
                    }
                }
            }
        }

        // Usage & Cost Graph
        if (history.isNotEmpty()) {
            item {
                UsageGraph(
                    history = history,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }
        }

        // Recent logs header
        item {
            Text(
                text = "RECENT USAGE LOGS",
                fontSize = 12.sp,
                fontFamily = DmSansFontFamily,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                letterSpacing = 0.5.sp,
                modifier = Modifier.padding(top = 4.dp)
            )
        }

        // History logs
        if (history.isEmpty()) {
            item {
                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "No usage logs recorded yet.",
                        fontSize = 11.sp,
                        fontFamily = DmSansFontFamily,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        modifier = Modifier.padding(10.dp)
                    )
                }
            }
        } else {
            items(history.take(5)) { item ->
                val sdf = SimpleDateFormat("MMM d", Locale.getDefault())
                val dateFormatted = sdf.format(Date(item.dateEpoch))

                Surface(
                    color = MaterialTheme.colorScheme.surface,
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = dateFormatted,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                            fontFamily = DmSansFontFamily,
                            fontSize = 12.sp
                        )
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = String.format(Locale.US, "%.1f kWh", item.consumptionKwh),
                                color = MaterialTheme.colorScheme.primary,
                                fontFamily = DmMonoFontFamily,
                                fontWeight = FontWeight.Medium,
                                fontSize = 12.sp
                            )
                            Text(
                                text = "৳${String.format(Locale.US, "%,.2f", item.cost)}",
                                color = MaterialTheme.colorScheme.onBackground,
                                fontFamily = DmMonoFontFamily,
                                fontWeight = FontWeight.Medium,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddAccountDialog(
    onDismiss: () -> Unit,
    onAdd: (String, String, String, String, Double, Double) -> Unit
) {
    var nickname by remember { mutableStateOf("") }
    var provider by remember { mutableStateOf("desco") }
    var accountNo by remember { mutableStateOf("") }
    var meterNo by remember { mutableStateOf("") }
    var balanceStr by remember { mutableStateOf("1000") }
    var monthlyKwhStr by remember { mutableStateOf("0") }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Add electricity account",
                        fontSize = 16.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "×",
                        fontSize = 28.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                        modifier = Modifier.clickable { onDismiss() }
                    )
                }

                OutlinedTextField(
                    value = nickname,
                    onValueChange = { nickname = it },
                    label = { Text("Nickname", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = MaterialTheme.colorScheme.onSurface,
                        unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline
                    )
                )

                // Provider selection dropdown simulation (simple Box clicking)
                var expandedProvider by remember { mutableStateOf(false) }
                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = when (provider) {
                            "desco" -> "DESCO (Dhaka Electric)"
                            else -> "Standard Progressive Utility"
                        },
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Distributor provider", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { expandedProvider = true },
                        trailingIcon = {
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = MaterialTheme.colorScheme.onSurface)
                        },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = MaterialTheme.colorScheme.onSurface,
                            unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        ),
                        enabled = false // Disable direct editing, enable clicking trigger
                    )
                    // Visual transparent overlay for click handling
                    Box(modifier = Modifier
                        .matchParentSize()
                        .clickable { expandedProvider = true })

                    DropdownMenu(
                        expanded = expandedProvider,
                        onDismissRequest = { expandedProvider = false },
                        modifier = Modifier
                            .fillMaxWidth(0.8f)
                            .background(MaterialTheme.colorScheme.surface)
                            .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                    ) {
                        DropdownMenuItem(
                            text = { Text("DESCO (Dhaka Electric)", color = MaterialTheme.colorScheme.onSurface, fontFamily = DmSansFontFamily) },
                            onClick = { provider = "desco"; expandedProvider = false }
                        )
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = accountNo,
                        onValueChange = { accountNo = it.filter { c -> c.isDigit() } },
                        label = { Text("Account number", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = MaterialTheme.colorScheme.onSurface,
                            unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        )
                    )

                    OutlinedTextField(
                        value = meterNo,
                        onValueChange = { meterNo = it.filter { c -> c.isDigit() } },
                        label = { Text("Meter number", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = MaterialTheme.colorScheme.onSurface,
                            unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        )
                    )
                }

                if (provider != "desco") {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = balanceStr,
                            onValueChange = { balanceStr = it },
                            label = { Text("Initial balance (৳)", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.weight(1f),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = MaterialTheme.colorScheme.onSurface,
                                unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                                focusedBorderColor = MaterialTheme.colorScheme.primary,
                                unfocusedBorderColor = MaterialTheme.colorScheme.outline
                            )
                        )

                        OutlinedTextField(
                            value = monthlyKwhStr,
                            onValueChange = { monthlyKwhStr = it },
                            label = { Text("Monthly kWh", fontSize = 11.sp, fontFamily = DmSansFontFamily) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.weight(1f),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = MaterialTheme.colorScheme.onSurface,
                                unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                                focusedBorderColor = MaterialTheme.colorScheme.primary,
                                unfocusedBorderColor = MaterialTheme.colorScheme.outline
                            )
                        )
                    }
                }

                Button(
                    onClick = {
                        val isDesco = provider == "desco"
                        val bal = if (isDesco) 0.0 else (balanceStr.toDoubleOrNull() ?: 0.0)
                        val kwh = if (isDesco) 0.0 else (monthlyKwhStr.toDoubleOrNull() ?: 0.0)
                        if (nickname.isNotBlank() && accountNo.isNotBlank() && meterNo.isNotBlank()) {
                            onAdd(nickname, provider, accountNo, meterNo, bal, kwh)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.surface
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Add account", fontWeight = FontWeight.Bold, fontFamily = DmSansFontFamily)
                }
            }
        }
    }
}

@Composable
fun UsageGraph(
    history: List<DailyUsageHistory>,
    modifier: Modifier = Modifier
) {
    if (history.isEmpty()) return

    // Get last 7 days of logs (chronological order)
    val data = history.take(7).reversed()

    val maxKwh = data.map { it.consumptionKwh }.maxOrNull()?.coerceAtLeast(0.1) ?: 0.1
    val maxCost = data.map { it.cost }.maxOrNull()?.coerceAtLeast(0.1) ?: 0.1
    val maxRate = 20.0

    val usageColor = StateOk
    val costColor = EmberOrange
    val rateColor = Color(0xFFD4AF37) // harmonious gold

    val onSurfaceColor = MaterialTheme.colorScheme.onSurface
    val outlineColor = MaterialTheme.colorScheme.outline

    Surface(
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = "Usage & cost trends (last 7 days)",
                fontSize = 11.sp,
                fontFamily = DmSansFontFamily,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(modifier = Modifier.size(8.dp, 2.dp).background(usageColor))
                    Text("Usage (kWh)", fontSize = 9.sp, fontFamily = DmSansFontFamily, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(modifier = Modifier.size(8.dp, 2.dp).background(costColor))
                    Text("Cost (৳)", fontSize = 9.sp, fontFamily = DmSansFontFamily, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(modifier = Modifier.size(8.dp, 1.dp).border(0.5.dp, rateColor))
                    Text("Rate/unit", fontSize = 9.sp, fontFamily = DmSansFontFamily, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
                }
            }

            val gridLineColor = onSurfaceColor.copy(alpha = 0.05f)
            val gridTextColor = onSurfaceColor.copy(alpha = 0.4f).toArgb()
            val rateTextColor = rateColor.copy(alpha = 0.5f).toArgb()

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(130.dp)
            ) {
                val paddingLeft = 90f
                val paddingRight = 60f
                val paddingTop = 15f
                val paddingBottom = 40f

                val chartWidth = size.width - paddingLeft - paddingRight
                val chartHeight = size.height - paddingTop - paddingBottom

                // Grid lines (horizontal)
                for (i in 0..4) {
                    val pct = i / 4f
                    val y = paddingTop + pct * chartHeight
                    drawLine(
                        color = gridLineColor,
                        start = androidx.compose.ui.geometry.Offset(paddingLeft, y),
                        end = androidx.compose.ui.geometry.Offset(size.width - paddingRight, y),
                        strokeWidth = 1f
                    )
                }

                // Tariff slab reference lines (dashed gold)
                val slabRates = listOf(5.32f, 6.18f, 8.50f)
                for (rate in slabRates) {
                    val y = paddingTop + chartHeight - (rate / maxRate.toFloat()) * chartHeight
                    drawLine(
                        color = rateColor.copy(alpha = 0.15f),
                        start = androidx.compose.ui.geometry.Offset(paddingLeft, y),
                        end = androidx.compose.ui.geometry.Offset(size.width - paddingRight, y),
                        strokeWidth = 1f,
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(6f, 6f))
                    )
                    drawContext.canvas.nativeCanvas.drawText(
                        "%.2f".format(rate),
                        size.width - paddingRight + 4f,
                        y + 4f,
                        android.graphics.Paint().apply {
                            color = rateTextColor
                            textSize = 18f
                        }
                    )
                }

                val xCoords = data.indices.map { idx ->
                    if (data.size <= 1) paddingLeft + chartWidth / 2f
                    else paddingLeft + (idx.toFloat() / (data.size - 1)) * chartWidth
                }

                val kwhPath = Path()
                val costPath = Path()
                val ratePath = Path()

                val sdf = SimpleDateFormat("MM/dd", Locale.US)

                data.forEachIndexed { i, d ->
                    val x = xCoords[i]
                    val yKwh = paddingTop + chartHeight - (d.consumptionKwh.toFloat() / maxKwh.toFloat()) * chartHeight
                    val yCost = paddingTop + chartHeight - (d.cost.toFloat() / maxCost.toFloat()) * chartHeight
                    val rate = if (d.consumptionKwh > 0.0) d.cost / d.consumptionKwh else 0.0
                    val yRate = paddingTop + chartHeight - (rate.toFloat() / maxRate.toFloat()) * chartHeight

                    if (i == 0) {
                        kwhPath.moveTo(x, yKwh)
                        costPath.moveTo(x, yCost)
                        ratePath.moveTo(x, yRate)
                    } else {
                        kwhPath.lineTo(x, yKwh)
                        costPath.lineTo(x, yCost)
                        ratePath.lineTo(x, yRate)
                    }

                    // Draw dots
                    drawCircle(color = usageColor, radius = 6f, center = androidx.compose.ui.geometry.Offset(x, yKwh))
                    drawCircle(color = costColor, radius = 6f, center = androidx.compose.ui.geometry.Offset(x, yCost))
                    drawCircle(color = rateColor, radius = 4f, center = androidx.compose.ui.geometry.Offset(x, yRate))

                    // Draw date text
                    val dateStr = sdf.format(Date(d.dateEpoch))
                    drawContext.canvas.nativeCanvas.drawText(
                        dateStr,
                        x,
                        size.height - 10f,
                        Paint().apply {
                            color = gridTextColor
                            textSize = 22f
                            textAlign = Paint.Align.CENTER
                            isAntiAlias = true
                        }
                    )
                }

                if (data.size > 1) {
                    drawPath(
                        path = kwhPath,
                        color = usageColor,
                        style = Stroke(width = 4f)
                    )
                    drawPath(
                        path = costPath,
                        color = costColor,
                        style = Stroke(width = 4f)
                    )
                    drawPath(
                        path = ratePath,
                        color = rateColor,
                        style = Stroke(width = 2.5f)
                    )
                }

                // Y-axis labels (Left: Max kWh, Right: Max ৳)
                drawContext.canvas.nativeCanvas.drawText(
                    String.format(Locale.US, "%.1f kWh", maxKwh),
                    paddingLeft - 10f,
                    paddingTop + 10f,
                    Paint().apply {
                        color = usageColor.toArgb()
                        textSize = 20f
                        textAlign = Paint.Align.RIGHT
                        isAntiAlias = true
                    }
                )

                drawContext.canvas.nativeCanvas.drawText(
                    String.format(Locale.US, "৳%.0f", maxCost),
                    size.width - paddingRight + 10f,
                    paddingTop + 10f,
                    Paint().apply {
                        color = costColor.toArgb()
                        textSize = 20f
                        textAlign = Paint.Align.LEFT
                        isAntiAlias = true
                    }
                )
            }
        }
    }
}
