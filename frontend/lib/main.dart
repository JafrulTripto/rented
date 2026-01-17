import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/tenant/presentation/pages/tenant_list_page.dart';
import 'package:frontend/features/tenant/presentation/pages/add_tenant_page.dart';
import 'package:frontend/features/rent/presentation/pages/add_rent_page.dart';
import 'package:frontend/features/rent/presentation/pages/rent_list_page.dart';
import 'package:frontend/features/auth/presentation/pages/auth_page.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/house/presentation/pages/house_list_page.dart';
import 'package:frontend/features/dashboard/presentation/pages/home_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  String _getTitle(String location) {
    if (location == '/') return 'Dashboard';
    if (location == '/tenants') return 'All Tenants';
    if (location == '/houses') return 'Houses';
    if (location == '/add-tenant') return 'Add Tenant';
    if (location.startsWith('/add-rent')) return 'Add Rent Payment';
    if (location.startsWith('/rents')) return 'Rent History';
    return 'Rented';
  }

  int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location == '/tenants') return 1;
    if (location == '/houses') return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _getTitle(location);
    final isTopLevel =
        location == '/' || location == '/tenants' || location == '/houses';
    final selectedIndex = _calculateSelectedIndex(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: isTopLevel
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/auth');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: isTopLevel
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                if (index == 0) context.go('/');
                if (index == 1) context.go('/tenants');
                if (index == 2) context.go('/houses');
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people_rounded),
                  label: 'Tenants',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.business_outlined),
                  activeIcon: Icon(Icons.business_rounded),
                  label: 'Houses',
                ),
              ],
            )
          : null,
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final loggingIn = state.uri.path == '/auth';
        if (!authState.isAuthenticated) {
          return '/auth';
        }
        if (loggingIn) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(
              path: '/tenants',
              builder: (context, state) =>
                  const TenantListPage(showDuesOnly: false),
            ),
            GoRoute(
              path: '/houses',
              builder: (context, state) => const HouseListPage(),
            ),
            GoRoute(
              path: '/add-tenant',
              builder: (context, state) => const AddTenantPage(),
            ),
            GoRoute(
              path: '/add-rent/:tenantId',
              builder: (context, state) {
                final tenantId = state.pathParameters['tenantId']!;
                return AddRentPage(tenantId: tenantId);
              },
            ),
            GoRoute(
              path: '/rents/:tenantId',
              builder: (context, state) {
                final tenantId = state.pathParameters['tenantId']!;
                return RentListPage(tenantId: tenantId);
              },
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Rented',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF14B8A6), // Vibrant Teal
          surface: const Color(0xFFF8FAFC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8),
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFF2DD4BF),
          surface: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          color: const Color(0xFF1E293B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF818CF8),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      routerConfig: router,
    );
  }
}
