import 'package:client/screens/employee_screen.dart';
import 'package:client/screens/home_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/screens/forgot_password_screen.dart';
import 'package:client/screens/profile_screen.dart';
import 'package:client/screens/change_password_screen.dart';
import 'package:client/services/auth_service.dart';
import 'package:client/widgets/navbar_admin.dart';
import 'package:client/models/employee_model.dart';
import 'package:client/screens/groupTwo/admin_dashboard_screen.dart';
import 'package:client/screens/groupTwo/department_crud_screen.dart';
import 'package:client/screens/groupTwo/edit_admin_employee_screen.dart';
import 'package:client/screens/groupTwo/edit_personal_screen.dart';
import 'package:client/screens/groupTwo/employee_detail_screen.dart';
import 'package:client/screens/groupTwo/employee_list_screen.dart';
import 'package:client/screens/groupTwo/position_crud_screen.dart';
import 'package:client/screens/groupTwo/role_selection_screen.dart';
import 'package:client/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'screens/admin_screen.dart';
import 'widgets/navbar_user.dart';

final GoRouter router = GoRouter(
  initialLocation: "/login",
  redirect: (context, state) {
    return AuthService.instance.redirectUser(state);
  },

  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavbarAdmin(navigationShell: navigationShell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: "/admin",
              builder: (context, state) => const AdminScreen(),
            ),
            GoRoute(
              path: "/admin/employee",
              builder: (context, state) => const EmployeeScreen(),
            ),
          ],
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavbarUser(navigationShell: navigationShell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: "/home",
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: "/profile",
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: "/forgot-password",
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: "/change-password",
      builder: (context, state) => const ChangePasswordScreen(),


    // ========================================
    // GROUP TWO ROUTES
    // ========================================

    // Role selection screen
    GoRoute(
      path: "/role-selection",
      builder: (context, state) => const RoleSelectionScreen(),
    ),

    // ========== KARYAWAN MODE ==========

    // Employee list (Karyawan mode)
    GoRoute(
      path: "/employee-list",
      builder: (context, state) =>
          const EmployeeListScreen(isKaryawanMode: true),
    ),

    // Employee detail
    GoRoute(
      path: "/employee-detail/:id",
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Data karyawan tidak ditemukan')),
          );
        }

        final employee = extra['employee'] as EmployeeModel;
        final isKaryawanMode = extra['isKaryawanMode'] as bool;

        return EmployeeDetailScreen(
          initialEmployee: employee, // UBAH NAMA PARAMETER
          isKaryawanMode: isKaryawanMode,
        );
      },
    ),

    // Edit personal info (Karyawan mode)
    GoRoute(
      path: "/employee/edit-personal/:id",
      builder: (context, state) {
        final employee = state.extra as EmployeeModel?;

        if (employee == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Data karyawan tidak ditemukan')),
          );
        }

        return EditPersonalScreen(employee: employee);
      },
    ),

    // ========== ADMIN MODE ==========

    // Admin dashboard
    GoRoute(
      path: "/admin-dashboard",
      builder: (context, state) => const AdminDashboardScreen(),
    ),

    // Admin - Employee list for management
    GoRoute(
      path: "/admin/employee-list",
      builder: (context, state) =>
          const EmployeeListScreen(isKaryawanMode: false),
    ),

    // Admin - Edit management
    GoRoute(
      path: "/employee/edit-management/:id",
      builder: (context, state) {
        final employee = state.extra as EmployeeModel?;

        if (employee == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Data karyawan tidak ditemukan')),
          );
        }

        return EditAdminEmployeeScreen(employee: employee);
      },
    ),

    // Admin - Position CRUD
    GoRoute(
      path: "/admin/positions",
      builder: (context, state) => const PositionCrudScreen(),
    ),

    // Admin - Department CRUD
    GoRoute(
      path: "/admin/departments",
      builder: (context, state) => const DepartmentCrudScreen(),
    ),
  ],
);
