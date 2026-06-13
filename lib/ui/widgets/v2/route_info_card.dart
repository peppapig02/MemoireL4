import 'package:botroad/ui/controllers/active_route_controller.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/primary_button.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RouteInfoCard extends StatelessWidget {
  final RouteCardInfo info;
  final String? messagePreview;

  const RouteInfoCard({
    super.key,
    required this.info,
    this.messagePreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.88,
      ),
      decoration: AppTokens.cardDecoration(glowing: true),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.route,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Itinéraire trouvé',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Row(icon: LucideIcons.circle, label: 'Départ', value: info.departure),
          const SizedBox(height: 8),
          _Row(
            icon: LucideIcons.mapPin,
            label: 'Destination',
            value: info.destination,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(
                icon: LucideIcons.ruler,
                text: '${info.distanceKm.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: LucideIcons.clock,
                text: '${info.durationMin.toStringAsFixed(0)} min',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Chip(icon: LucideIcons.trafficCone, text: info.trafficStatus),
          const SizedBox(height: 4),
          _Chip(icon: LucideIcons.construction, text: info.roadQuality),
          if (info.warningCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${info.warningCount} alerte(s) sur la route',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Voir sur la carte',
            icon: LucideIcons.map,
            onPressed: () {
              Get.find<ActiveRouteController>().setActiveRoute(info.route);
              switchMainTab(1);
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
