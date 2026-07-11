package com.example.bonermohis.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.bonermohis.data.Account
import com.example.bonermohis.data.DailyUsageHistory
import com.example.bonermohis.data.ElectricityRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class DashboardViewModel(private val repository: ElectricityRepository) : ViewModel() {

    val accounts: StateFlow<List<Account>> = repository.allAccounts
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedAccountId = MutableStateFlow<Int?>(null)
    val selectedAccountId = _selectedAccountId.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    val selectedAccountHistory: StateFlow<List<DailyUsageHistory>> = _selectedAccountId
        .flatMapLatest { id ->
            if (id != null) repository.getHistoryFlow(id) else flowOf(emptyList())
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun selectAccount(id: Int) {
        _selectedAccountId.value = id
    }

    fun simulateDay() {
        val id = _selectedAccountId.value ?: return
        viewModelScope.launch {
            repository.simulateDay(id)
        }
    }

    fun resetCycle() {
        val id = _selectedAccountId.value ?: return
        viewModelScope.launch {
            repository.resetCycle(id)
        }
    }

    fun topUp(amount: Double) {
        val id = _selectedAccountId.value ?: return
        viewModelScope.launch {
            repository.topUp(id, amount)
        }
    }

    fun deleteAccount() {
        val id = _selectedAccountId.value ?: return
        viewModelScope.launch {
            repository.deleteAccount(id)
            _selectedAccountId.value = accounts.value.firstOrNull { it.id != id }?.id
        }
    }

    fun syncLive() {
        val id = _selectedAccountId.value ?: return
        viewModelScope.launch {
            repository.syncAccount(id)
        }
    }

    fun addAccount(
        nickname: String,
        distributor: String,
        accountNo: String,
        meterNo: String,
        initialBalance: Double,
        monthlyKwh: Double
    ) {
        viewModelScope.launch {
            val isDesco = distributor == "desco"
            val newAccount = Account(
                nickname = nickname,
                distributor = distributor,
                accountNo = accountNo,
                meterNo = meterNo,
                balance = if (isDesco) 0.0 else initialBalance,
                lastUpdated = System.currentTimeMillis(),
                currentSlab = 0,
                slabUsage = 0.0,
                yesterdayUsage = 0.0,
                monthlyKwh = if (isDesco) 0.0 else monthlyKwh
            )
            val newId = repository.insertAccount(newAccount).toInt()
            _selectedAccountId.value = newId
            if (isDesco) {
                repository.syncAccount(newId)
            }
        }
    }

    class Factory(private val repository: ElectricityRepository) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            if (modelClass.isAssignableFrom(DashboardViewModel::class.java)) {
                return DashboardViewModel(repository) as T
            }
            throw IllegalArgumentException("Unknown ViewModel class")
        }
    }
}
