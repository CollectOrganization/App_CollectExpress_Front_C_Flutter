import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final VoidCallback? onTap;

  const AppLogo({super.key, this.onTap});

  void _goHome(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == AppRoutes.home) {
      return;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Ir para o início',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _goHome(context),
            hoverColor: AppColors.green.withValues(alpha: 0.08),
            splashColor: AppColors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLLECT',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 42, height: 3, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        'XPRESS',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF77A644),
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
