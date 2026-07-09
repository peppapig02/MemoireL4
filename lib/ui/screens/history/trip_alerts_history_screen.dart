import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/wapi_loader.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripAlertsHistoryScreen extends StatefulWidget {
  const TripAlertsHistoryScreen({super.key});

  @override
  State<TripAlertsHistoryScreen> createState() =>
      _TripAlertsHistoryScreenState();
}

class _TripAlertsHistoryScreenState extends State<TripAlertsHistoryScreen> {
  late final TripHistoryService tripHistoryService;
  late Future<List<TripHistory>> tripsFuture;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    tripHistoryService = TripHistoryService(collection: Setting.fTripHistory);
    tripsFuture = _loadTrips();
  }

  Future<List<TripHistory>> _loadTrips() async {
    final userId = Setting.userCtrl.user.value.key;
    if (userId == null || userId.isEmpty) {
      return const [];
    }
    return tripHistoryService.getTripHistoryForUser(userId, limit: 50);
  }

  Future<void> _refresh() async {
    setState(() {
      tripsFuture = _loadTrips();
    });
    await tripsFuture;
  }

  List<TripHistory> _applyFilter(List<TripHistory> trips) {
    return trips.where((trip) {
      return switch (filter) {
        'with_alerts' => trip.warnings.isNotEmpty,
        'without_alerts' => trip.warnings.isEmpty,
        _ => true,
      };
    }).toList();
  }

  _TripAlertStats _calculateStats(List<TripHistory> trips) {
    var tripsWithAlerts = 0;
    var totalAlerts = 0;
    var highSeverityAlerts = 0;

    for (final trip in trips) {
      if (trip.warnings.isNotEmpty) {
        tripsWithAlerts++;
      }
      totalAlerts += trip.warnings.length;
      highSeverityAlerts +=
          trip.warnings
              .where((warning) => warning['severity'] == 'eleve')
              .length;
    }

    return _TripAlertStats(
      totalTrips: trips.length,
      tripsWithAlerts: tripsWithAlerts,
      totalAlerts: totalAlerts,
      highSeverityAlerts: highSeverityAlerts,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date inconnue';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a $hour:$minute';
  }

  String _formatTripTitle(TripHistory trip) {
    final origin =
        trip.originLabel?.trim().isNotEmpty == true
            ? trip.originLabel!
            : 'Depart inconnu';
    final destination =
        trip.destinationLabel?.trim().isNotEmpty == true
            ? trip.destinationLabel!
            : 'Destination inconnue';
    return '$origin -> $destination';
  }

  String _formatType(dynamic type) {
    final value = (type ?? 'alerte').toString();
    return value.replaceAll('_', ' ');
  }

  Color _severityColor(dynamic severity) {
    return switch (severity?.toString()) {
      'eleve' => AppColors.error,
      'moyen' => AppColors.warning,
      _ => AppColors.success,
    };
  }

  String _formatWarningLocation(Map<String, dynamic> warning) {
    final label = warning['locationLabel']?.toString().trim();
    final address = warning['locationAddress']?.toString().trim();
    final segment = warning['segmentId']?.toString().trim();
    final route = warning['routeId']?.toString().trim();

    if (label != null &&
        label.isNotEmpty &&
        address != null &&
        address.isNotEmpty) {
      return 'Pres de $label - $address';
    }
    if (label != null && label.isNotEmpty) {
      return 'Pres de $label';
    }
    if (address != null && address.isNotEmpty) {
      return address;
    }
    if (segment != null && segment.isNotEmpty) {
      return 'Sur le segment $segment';
    }
    if (route != null && route.isNotEmpty) {
      return 'Sur la route $route';
    }

    return 'Reference precise non renseignee';
  }

  void _closeBottomSheet() {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  Widget _buildStats(List<TripHistory> trips) {
    final stats = _calculateStats(trips);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final tileWidth = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _StatTile(
                width: tileWidth,
                icon: Icons.route,
                label: 'Trajets',
                value: '${stats.totalTrips}',
                color: AppColors.primary,
              ),
              _StatTile(
                width: tileWidth,
                icon: Icons.warning_amber_rounded,
                label: 'Avec alertes',
                value: '${stats.tripsWithAlerts}',
                color: AppColors.error,
              ),
              _StatTile(
                width: tileWidth,
                icon: Icons.report_problem_outlined,
                label: 'Alertes detectees',
                value: '${stats.totalAlerts}',
                color: AppColors.warning,
              ),
              _StatTile(
                width: tileWidth,
                icon: Icons.priority_high,
                label: 'Gravite elevee',
                value: '${stats.highSeverityAlerts}',
                color: AppColors.error,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChipButton(
              selected: filter == 'all',
              label: 'Tous',
              onTap: () => setState(() => filter = 'all'),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              selected: filter == 'with_alerts',
              label: 'Avec alertes',
              onTap: () => setState(() => filter = 'with_alerts'),
            ),
            const SizedBox(width: 8),
            _FilterChipButton(
              selected: filter == 'without_alerts',
              label: 'Sans alertes',
              onTap: () => setState(() => filter = 'without_alerts'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetails(TripHistory trip) {
    Get.bottomSheet(
      Container(
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: const Icon(Icons.route, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTripTitle(trip),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatDate(trip.createdAt)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Resume du trajet',
                  children: [
                    _DetailRow(
                      label: 'Distance',
                      value: '${trip.distance.toStringAsFixed(1)} km',
                    ),
                    _DetailRow(
                      label: 'Duree',
                      value: '${trip.duration.toStringAsFixed(0)} min',
                    ),
                    _DetailRow(
                      label: 'Segments',
                      value: '${trip.segments.length}',
                    ),
                    _DetailRow(
                      label: 'Alertes',
                      value: '${trip.warnings.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Alertes detectees',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (trip.warnings.isEmpty)
                  Text(
                    'Aucune alerte n a ete detectee sur ce trajet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...trip.warnings.map(_buildWarningDetail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningDetail(Map<String, dynamic> warning) {
    final color = _severityColor(warning['severity']);
    final createdAt = DateTime.tryParse(
      (warning['createdAt'] ?? '').toString(),
    );
    final expiresAt = DateTime.tryParse(
      (warning['expiresAt'] ?? '').toString(),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatType(warning['type']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _SeverityPill(
                label: (warning['severity'] ?? 'faible').toString(),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Statut',
            value: (warning['status'] ?? 'pending').toString(),
          ),
          _DetailRow(label: 'Signalement', value: _formatDate(createdAt)),
          _DetailRow(label: 'Lieu', value: _formatWarningLocation(warning)),
          _DetailRow(label: 'Expiration', value: _formatDate(expiresAt)),
          _DetailRow(
            label: 'Rayon',
            value:
                '${((warning['radiusMeters'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} m',
          ),
          _DetailRow(
            label: 'Avis',
            value:
                '${warning['confirmationCount'] ?? 0} confirmation(s), ${warning['refutationCount'] ?? 0} refutation(s)',
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripHistory trip) {
    final warningCount = trip.warnings.length;
    final highSeverityCount =
        trip.warnings.where((warning) => warning['severity'] == 'eleve').length;
    final hasWarnings = warningCount > 0;

    return Container(
      decoration: AppTokens.cardDecoration(),
      child: InkWell(
        borderRadius: AppTokens.borderRadiusCard,
        onTap: () => _showTripDetails(trip),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: hasWarnings
                    ? AppColors.warning.withValues(alpha: 0.14)
                    : AppColors.success.withValues(alpha: 0.14),
                child: Icon(
                  hasWarnings
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: hasWarnings ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTripTitle(trip),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(_formatDate(trip.createdAt)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.alt_route,
                          label:
                              '${trip.distance.toStringAsFixed(1)} km - ${trip.duration.toStringAsFixed(0)} min',
                        ),
                        _InfoPill(
                          icon: Icons.warning_amber_rounded,
                          label: '$warningCount alerte(s)',
                        ),
                        if (highSeverityCount > 0)
                          _InfoPill(
                            icon: Icons.priority_high,
                            label: '$highSeverityCount elevee(s)',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes par trajet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<TripHistory>>(
        future: tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: WapiLoader(size: 48));
          }

          final trips = snapshot.data ?? const <TripHistory>[];
          if (trips.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun trajet enregistre pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final filteredTrips = _applyFilter(trips);

          return Column(
            children: [
              _buildStats(trips),
              _buildFilters(),
              Expanded(
                child:
                    filteredTrips.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aucun trajet ne correspond au filtre.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTrips.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder:
                                (context, index) =>
                                    _buildTripCard(filteredTrips[index]),
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TripAlertStats {
  final int totalTrips;
  final int tripsWithAlerts;
  final int totalAlerts;
  final int highSeverityAlerts;

  const _TripAlertStats({
    required this.totalTrips,
    required this.tripsWithAlerts,
    required this.totalAlerts,
    required this.highSeverityAlerts,
  });
}

class _StatTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: AppTokens.neumorphicDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? AppTokens.glowAccent(opacity: 0.3)
              : AppTokens.neumorphicRaised(intensity: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
