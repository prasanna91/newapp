import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/bottom_navigation.dart';
import 'web_view_screen.dart';
import '../config/env_config.dart';
import 'notification_settings_screen.dart';

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: EnvConfig.pushNotify
              ? AppBar(
                  title: Text(EnvConfig.appName),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Notification Settings',
                    ),
                  ],
                )
              : null,
          body: Column(
            children: [
              // Main content area
              Expanded(
                child: WebViewScreen(
                  initialUrl: appState.currentUrl,
                  onUrlChanged: (url) {
                    appState.setCurrentUrl(url);
                  },
                ),
              ),

              // Bottom navigation
              if (EnvConfig.isBottommenu && appState.bottomMenuItems.isNotEmpty)
                CustomBottomNavigation(
                  items: appState.bottomMenuItems,
                  currentIndex: appState.currentTabIndex,
                  onTap: (index) {
                    appState.setCurrentTabIndex(index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
