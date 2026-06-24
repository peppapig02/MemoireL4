import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    (icon: CupertinoIcons.chat_bubble_2_fill, label: 'Assistant'),
    (icon: CupertinoIcons.map_fill, label: 'Carte'),
    (icon: CupertinoIcons.exclamationmark_triangle_fill, label: 'Alertes'),
    (icon: CupertinoIcons.clock_fill, label: 'Historique'),
    (icon: CupertinoIcons.person_fill, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTokens.borderRadiusNav,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppTokens.shadowSoft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = currentIndex == index;
          final isAssistant = index == 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isActive ? 8 : 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isActive && isAssistant
                          ? AppTokens.glowAccent(opacity: 0.15)
                          : null,
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color:
                          isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isActive ? AppColors.primary : AppColors.textMuted,
                    ),
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
