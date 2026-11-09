package com.cronicle.app.cronicle.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.cronicle.app.cronicle.wear.ui.DetailScreen
import com.cronicle.app.cronicle.wear.ui.LibraryScreen

class MainActivity : ComponentActivity() {
    private val viewModel: LibraryViewModel by viewModels { LibraryViewModel.Factory(application) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { CronicleWearApp(viewModel) }
    }

    override fun onResume() {
        super.onResume()
        viewModel.refresh()
    }
}

@Composable
private fun CronicleWearApp(viewModel: LibraryViewModel) {
    MaterialTheme {
        val navController = rememberSwipeDismissableNavController()
        val state by viewModel.state.collectAsState()
        var selectedKey by remember { mutableStateOf<String?>(null) }

        SwipeDismissableNavHost(
            navController = navController,
            startDestination = "library",
        ) {
            composable("library") {
                LibraryScreen(
                    state = state,
                    onRefresh = { viewModel.refresh() },
                    onItemClick = { item ->
                        selectedKey = "${item.kind}:${item.externalId}"
                        navController.navigate("detail")
                    },
                    onIncrement = viewModel::increment,
                )
            }
            composable("detail") {
                val item = state.items.firstOrNull { "${it.kind}:${it.externalId}" == selectedKey }
                DetailScreen(
                    item = item,
                    onIncrement = { it?.let(viewModel::increment) },
                    onComplete = { it?.let(viewModel::complete) },
                    onBack = { navController.popBackStack() },
                )
            }
        }
    }
}
