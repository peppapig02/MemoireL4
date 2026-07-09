import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: LucideIcons.messageCircle, label: 'Assistant'),
    (icon: LucideIcons.map, label: 'Carte'),
    (icon: LucideIcons.triangleAlert, label: 'Alertes'),
    (icon: LucideIcons.history, label: 'Trajets'),
    (icon: LucideIcons.user, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: AppTokens.neumorphicDecoration(
        borderRadius: AppTokens.borderRadiusNav,
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Glass fill — teinté primary mais transparent
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      // Glass rim
                      border: isActive
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.32),
                              width: 1.2,
                            )
                          : null,
                      // Glow + relief "enfoncé" pour la pastille active
                      boxShadow: isActive
                          ? [
                              ...AppTokens.neumorphicPressed(intensity: 0.6),
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          key: ValueKey(isActive),
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
