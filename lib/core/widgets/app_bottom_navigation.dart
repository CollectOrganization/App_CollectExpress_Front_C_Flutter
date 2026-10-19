import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_service.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    this.currentIndex = 0,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    final user = AuthService.currentUserNotifier.value;
    final isAdmin = user?['tipo_perfil'] == 'ADMIN';

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/cacambas');
        break;
      case 2:
        if (isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin/pedidos');
        } else {
          Navigator.of(context).pushReplacementNamed('/pedidos');
        }
        break;
      case 3:
        if (isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else if (user != null) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushNamed('/login');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        final isAdmin = user?['tipo_perfil'] == 'ADMIN';

        return BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.green,
          unselectedItemColor: Colors.black54,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) => _onItemTapped(context, index),
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
              label: isAdmin ? 'Gestão' : 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: isAdmin ? 'Admin' : 'Perfil',
            ),
          ],
        );
      },
    );
  }
}
