import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/sessao_provider.dart';
import '../models/enums.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';

void _navigateToTab(
  BuildContext context,
  int selectedIndex,
  int currentIndex,
  List<String> routes,
) {
  if (selectedIndex == currentIndex) return;

  Navigator.of(context)
      .pushNamedAndRemoveUntil(routes[selectedIndex], (route) => false);
}

/// Barra das telas públicas e do cliente. As duas últimas abas levam cada
/// perfil para a sua área: pedidos e perfil do cliente, gestão e painel do
/// fornecedor ou do admin. Sem login, "Perfil" abre o login.
class CustomerBottomNavigation extends ConsumerWidget {
  final int currentIndex;

  const CustomerBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(sessaoProvider).value?.tipoPerfil;

    final (labelGestao, rotaGestao, labelPainel, rotaPainel) = switch (perfil) {
      TipoPerfil.cacambeiro => (
        'Gestão',
        AppRoutes.supplierOrders,
        'Painel',
        AppRoutes.supplierHome,
      ),
      TipoPerfil.admin => (
        'Gestão',
        AppRoutes.adminUsers,
        'Admin',
        AppRoutes.adminHome,
      ),
      TipoPerfil.consumidor => (
        'Pedidos',
        AppRoutes.customerOrders,
        'Perfil',
        AppRoutes.customerProfile,
      ),
      null => ('Pedidos', AppRoutes.customerOrders, 'Perfil', null),
    };

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        if (index == 3 && rotaPainel == null) {
          Navigator.of(context).pushNamed(AppRoutes.login);
          return;
        }

        _navigateToTab(context, index, currentIndex, [
          AppRoutes.home,
          AppRoutes.services,
          rotaGestao,
          rotaPainel ?? AppRoutes.login,
        ]);
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          activeIcon: Icon(Icons.delete),
          label: 'Caçambas',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_alt_outlined),
          activeIcon: const Icon(Icons.list_alt),
          label: labelGestao,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: labelPainel,
        ),
      ],
    );
  }
}

class SupplierBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const SupplierBottomNavigation({super.key, required this.currentIndex});

  static const routes = [
    AppRoutes.supplierHome,
    AppRoutes.supplierDumpsters,
    AppRoutes.supplierOrders,
    AppRoutes.supplierProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        _navigateToTab(context, index, currentIndex, routes);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          activeIcon: Icon(Icons.delete),
          label: 'Caçambas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

class PlatformAdminBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const PlatformAdminBottomNavigation({super.key, required this.currentIndex});

  static const routes = [
    AppRoutes.adminHome,
    AppRoutes.adminUsers,
    AppRoutes.adminPartners,
    AppRoutes.adminFinance,
    AppRoutes.adminSettings,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        _navigateToTab(context, index, currentIndex, routes);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}

class RecyclingBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const RecyclingBottomNavigation({super.key, required this.currentIndex});

  static const routes = [
    AppRoutes.recyclingMaterials,
    AppRoutes.recyclingPartners,
    AppRoutes.recyclingCollections,
    AppRoutes.recyclingProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (index) {
        _navigateToTab(context, index, currentIndex, routes);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.recycling_outlined),
          activeIcon: Icon(Icons.recycling),
          label: 'Materiais',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handshake_outlined),
          activeIcon: Icon(Icons.handshake),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Coletas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
