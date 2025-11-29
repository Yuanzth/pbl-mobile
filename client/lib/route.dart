import 'package:client/screens/home_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/screens/splash_screen.dart'; // 1. Import Splash Screen
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  // 2. Ubah initialLocation ke '/splash'
  initialLocation: "/splash",

  redirect: (context, state) {
    return null; // Biarkan null dulu jika logika ada di dalam widget Splash
  },

  routes: [
    // 3. Tambahkan Route untuk Splash Screen
    GoRoute(
      path: "/splash",
      name: "splash",
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: "/",
      name: "home",
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: "/login",
      name: "login",
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
