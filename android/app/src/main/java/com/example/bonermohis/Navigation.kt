package com.example.bonermohis

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.ui.NavDisplay
import com.example.bonermohis.ui.DashboardScreen
import com.example.bonermohis.ui.DashboardViewModel

@Composable
fun MainNavigation() {
  val backStack = rememberNavBackStack(Main)

  NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider =
      entryProvider {
        entry<Main> {
          val context = LocalContext.current.applicationContext as AppApplication
          val repository = context.repository
          val viewModel: DashboardViewModel = viewModel(
            factory = DashboardViewModel.Factory(repository)
          )
          DashboardScreen(
            viewModel = viewModel,
            modifier = Modifier.safeDrawingPadding()
          )
        }
      },
  )
}
