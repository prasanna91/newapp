import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/env_config.dart';
import 'providers/app_state_provider.dart';
import 'services/notification_handler.dart';
import 'widgets/splash_screen.dart';
import 'screens/main_app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuikAppBuildSystem());
}

class QuikAppBuildSystem extends StatelessWidget {
  const QuikAppBuildSystem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
      child: MaterialApp(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: EnvConfig.bottommenuFont,
          useMaterial3: true,
        ),
        home: const AppWrapper(),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  final NotificationHandler _notificationHandler = NotificationHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotificationHandler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeNotificationHandler() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await _notificationHandler.initialize(appState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.paused:
        appState.setAppInBackground(true);
        break;
      case AppLifecycleState.resumed:
        appState.setAppInBackground(false);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isSplashVisible) {
          return const SplashScreen();
        } else {
          return const MainAppScreen();
        }
      },
    );
  }
}
