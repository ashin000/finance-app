import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'services/database/database_service.dart';
import 'services/firebase/firebase_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/lock_provider.dart';
import 'features/auth/lock_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/reports/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Hive Local Database Cache
  await DatabaseService.instance.init();

  // 2. Initialize Firebase (Offline fallback ready)
  await FirebaseService.instance.init();

  runApp(
    const ProviderScope(
      child: PayVoiceApp(),
    ),
  );
}

// Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Read auth provider state directly
    final container = ProviderScope.containerOf(context);
    final auth = container.read(authProvider);
    final isLocked = container.read(lockProvider);

    final isLoggingIn = state.matchedLocation == '/auth';
    final isLockPage = state.matchedLocation == '/lock';

    // If user is not logged in, force navigation to /auth
    if (auth.user == null) {
      return isLoggingIn ? null : '/auth';
    }

    // If logged in, but app is biometric locked, force navigation to /lock
    if (isLocked) {
      return isLockPage ? null : '/lock';
    }

    // If logged in and going to auth or lock screen, redirect to home
    if (isLoggingIn || isLockPage) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationContainer(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);

final tabIndexProvider = StateProvider<int>((ref) => 0);

class PayVoiceApp extends ConsumerWidget {
  const PayVoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Auth State to trigger Router redirection on login/logout changes
    ref.listen(authProvider, (previous, next) {
      if (previous?.user != next.user) {
        _router.refresh();
      }
    });

    // Listen to Lock State to trigger Router redirection on unlock
    ref.listen(lockProvider, (previous, next) {
      if (previous != next) {
        _router.refresh();
      }
    });

    final settings = ref.watch(settingsProvider);
    final themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: 'PayVoice AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

class MainNavigationContainer extends ConsumerStatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  ConsumerState<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends ConsumerState<MainNavigationContainer> with WidgetsBindingObserver {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const AnalyticsScreen(),
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(lockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(tabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: "Ledger",
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: "Analytics",
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: "Budgets",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: "Settings",
          ),
        ],
      ),
      // Adding a FloatingActionButton for Quick Statement Export Routing
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/reports'),
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text("Export Statement"),
            )
          : null,
    );
  }
}
