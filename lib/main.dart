import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

// Import your features here
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/data/auth_repository.dart';

Future<void> main() async {
  // Ensure widgets are bound before initializing backend
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: FamilyPlannerApp()));
}

/// The root application widget.
class FamilyPlannerApp extends ConsumerWidget {
  const FamilyPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Family Planner',
      debugShowCheckedModeBanner: false,

      // Localization Support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate, // Essential for Syncfusion
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Portuguese, Brazil
      ],
      locale: const Locale('pt', 'BR'),

      // Theme Configuration (Material 3 & Centralized Theme Rule)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50), // Nice dark blue-grey base
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system, // Supports auto-switching
      // Router Config
      routerConfig: router,
    );
  }
}

// ------------------------------------------------------------------
// ROUTER CONFIGURATION (The "Traffic Cop")
// ------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  // Watch the auth state. If it changes (login/logout), the router rebuilds.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // Prints route changes to console
    // This creates a "Listenable" that triggers a refresh whenever Auth changes
    refreshListenable: AuthStateListenable(authState),

    redirect: (context, state) {
      // 1. Check current auth status
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;

      final isLoginRoute = state.uri.toString() == '/login';

      // 2. Redirect Logic
      if (!isAuthenticated) {
        // If not logged in and not on login page, go to login
        return isLoginRoute ? null : '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        // If logged in and trying to go to login, send to dashboard
        return '/';
      }

      // No redirect needed
      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
    ],
  );
});

// A wrapper to convert AsyncValue<AuthState> into a Listenable for GoRouter
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(AsyncValue<AuthState> provider) {
    // Notify router when the stream emits a new value
    if (provider.hasValue) {
      notifyListeners();
    }
  }
}
