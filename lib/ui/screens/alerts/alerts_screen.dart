import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/ui/animations/skeleton.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/app_card.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AlertsScreen extends StatefulWidget {
  final bool embedded;

  const AlertsScreen({super.key, this.embedded = true});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final RoadReportService roadReportService;
  late Future<List<RoadReport>> alertsFuture;
  String statusFilter = 'all';
  String typeFilter = 'all';
  String severityFilter = 'all';
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    roadReportService = RoadReportService(collection: Setting.fRoadReports);
    alertsFuture = _loadAlerts();
    RoadReportService.refreshRevision.addListener(_handleReportsChanged);
  }

  @override
  void dispose() {
    RoadReportService.refreshRevision.removeListener(_handleReportsChanged);
    super.dispose();
  }

  void _handleReportsChanged() {
    if (!mounted) return;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      alertsFuture = _loadAlerts();
    });
    await alertsFuture;
  }

  Future<List<RoadReport>> _loadAlerts() async {
    final alerts = await roadReportService.getActiveRoadReports(limit: 100);
    currentPosition = await _getCurrentPositionIfAllowed();
    return _sortAlertsByDistance(alerts);
  }

  Future<Position?> _getCurrentPositionIfAllowed() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  List<RoadReport> _sortAlertsByDistance(List<RoadReport> alerts) {
    final position = currentPosition;
    final sorted = alerts.toList();
    if (position == null) {
      return sorted;
    }

    sorted.sort((a, b) {
      final aDistance = _distanceFromCurrent(a) ?? double.infinity;
      final bDistance = _distanceFromCurrent(b) ?? double.infinity;
      return aDistance.compareTo(bDistance);
    });
    return sorted;
  }

  double? _distanceFromCurrent(RoadReport alert) {
    final position = currentPosition;
    if (position == null || (alert.latitude == 0 && alert.longitude == 0)) {
      return null;
    }

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          alert.latitude,
          alert.longitude,
        ) /
        1000;
  }

  String _formatDistanceFromCurrent(RoadReport alert) {
    final distance = _distanceFromCurrent(alert);
    if (distance == null) {
      return 'Distance indisponible';
    }
    if (distance < 1) {
      return '${(distance * 1000).round()} m de vous';
    }
    return '${distance.toStringAsFixed(1)} km de vous';
  }

  String _formatLocationReference(RoadReport alert) {
    final label = alert.locationLabel?.trim();
    final address = alert.locationAddress?.trim();
    final segment = alert.segmentId?.trim();
    final route = alert.routeId?.trim();
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
    Navigator.of(Get.overlayContext ?? context, rootNavigator: true).maybePop();
  }

  Future<void> _markHandled(RoadReport report) async {
    if (report.id == null) {
      return;
    }

    final ok = await roadReportService.markReportHandled(report.id!);
    Setting.showMessage(
      ok ? 'login_verification'.tr : 'login_error'.tr,
      ok
          ? 'Alerte marquee comme prise en charge.'
          : 'Impossible de mettre a jour cette alerte.',
      ok ? Colors.green : Colors.red,
    );
    if (ok) {
      await _refresh();
    }
  }

  Future<void> _vote(RoadReport report, {required bool confirms}) async {
    final reportId = report.id;
    final voterId = Setting.userCtrl.user.value.key;
    if (reportId == null || voterId == null) {
      Setting.showMessage(
        'login_error'.tr,
        'Impossible d identifier l utilisateur.',
        Colors.red,
      );
      return;
    }

    final ok =
        confirms
            ? await roadReportService.confirmReport(
              reportId: reportId,
              voterId: voterId,
            )
            : await roadReportService.refuteReport(
              reportId: reportId,
              voterId: voterId,
            );

    Setting.showMessage(
      ok ? 'login_verification'.tr : 'login_error'.tr,
      ok
          ? (confirms ? 'Alerte confirmee.' : 'Alerte refutee.')
          : 'Impossible de mettre a jour votre avis.',
      ok ? Colors.green : Colors.red,
    );
    if (ok) {
      await _refresh();
    }
  }

  Future<void> _deleteAlert(RoadReport report) async {
    if (report.id == null) {
      return;
    }

    final confirmed = await Get.defaultDialog<bool>(
      title: 'Supprimer l alerte',
      middleText: 'Voulez-vous vraiment supprimer cette alerte ?',
      textCancel: 'Annuler',
      textConfirm: 'Supprimer',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
    );

    if (confirmed != true) {
      return;
    }

    final ok = await roadReportService.deleteReport(report.id!);
    Setting.showMessage(
      ok ? 'login_verification'.tr : 'login_error'.tr,
      ok ? 'Alerte supprimee.' : 'Impossible de supprimer cette alerte.',
      ok ? Colors.green : Colors.red,
    );
    if (ok) {
      await _refresh();
    }
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

  String _formatType(String type) {
    return type.replaceAll('_', ' ');
  }

  String _formatStatus(String status) {
    if (status == 'handled') {
      return 'Pris en charge';
    }
    if (status == 'deleted') {
      return 'Supprimee';
    }
    return 'Non pris en charge';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'eleve':
        return AppColors.error;
      case 'moyen':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  _AlertStats _calculateStats(List<RoadReport> alerts) {
    final typeCounts = <String, int>{};
    final severityCounts = <String, int>{};
    var activeCount = 0;
    var handledCount = 0;
    var expiredCount = 0;
    var confirmationCount = 0;
    var refutationCount = 0;

    for (final alert in alerts) {
      if (alert.isActive) {
        activeCount++;
      }
      if (alert.status == 'handled') {
        handledCount++;
      }
      if (!alert.isActive && alert.status != 'deleted') {
        expiredCount++;
      }

      confirmationCount += alert.confirmationCount;
      refutationCount += alert.refutationCount;
      typeCounts.update(alert.type, (value) => value + 1, ifAbsent: () => 1);
      severityCounts.update(
        alert.severity,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return _AlertStats(
      total: alerts.length,
      active: activeCount,
      handled: handledCount,
      expired: expiredCount,
      confirmations: confirmationCount,
      refutations: refutationCount,
      topType: _mostFrequentValue(typeCounts),
      dominantSeverity: _mostFrequentValue(severityCounts),
    );
  }

  String _mostFrequentValue(Map<String, int> counts) {
    if (counts.isEmpty) {
      return 'Aucun';
    }

    final entries =
        counts.entries.toList()..sort((a, b) {
          final countComparison = b.value.compareTo(a.value);
          if (countComparison != 0) {
            return countComparison;
          }
          return a.key.compareTo(b.key);
        });
    return entries.first.key;
  }

  Widget _buildStats(List<RoadReport> alerts) {
    final stats = _calculateStats(alerts);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatTile(
                icon: LucideIcons.triangleAlert,
                label: 'Total',
                value: '${stats.total}',
                color: AppColors.primary,
              ),
              _StatTile(
                icon: LucideIcons.radar,
                label: 'Actives',
                value: '${stats.active}',
                color: AppColors.error,
              ),
              _StatTile(
                icon: LucideIcons.circleCheck,
                label: 'Prises en charge',
                value: '${stats.handled}',
                color: AppColors.success,
              ),
              _StatTile(
                icon: LucideIcons.clock,
                label: 'Expirees',
                value: '${stats.expired}',
                color: AppColors.textMuted,
              ),
              _StatTile(
                icon: LucideIcons.layers,
                label: 'Type frequent',
                value: _formatType(stats.topType),
                color: AppColors.info,
              ),
              _StatTile(
                icon: LucideIcons.signalHigh,
                label: 'Gravite dominante',
                value: stats.dominantSeverity,
                color: _severityColor(stats.dominantSeverity),
              ),
              _StatTile(
                icon: LucideIcons.thumbsUp,
                label: 'Confirmations',
                value: '${stats.confirmations}',
                color: AppColors.success,
              ),
              _StatTile(
                icon: LucideIcons.thumbsDown,
                label: 'Refutations',
                value: '${stats.refutations}',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<RoadReport> _applyFilters(List<RoadReport> alerts) {
    return alerts.where((alert) {
      final matchesStatus = switch (statusFilter) {
        'active' => alert.isActive,
        'handled' => alert.status == 'handled',
        'pending' => alert.status != 'handled' && alert.isActive,
        'expired' => !alert.isActive && alert.status != 'deleted',
        _ => true,
      };
      final matchesType = typeFilter == 'all' || alert.type == typeFilter;
      final matchesSeverity =
          severityFilter == 'all' || alert.severity == severityFilter;
      return matchesStatus && matchesType && matchesSeverity;
    }).toList();
  }

  List<String> _availableTypes(List<RoadReport> alerts) {
    final types = alerts.map((alert) => alert.type).toSet().toList();
    types.sort();
    return types;
  }

  List<RoadReport> _mapAlerts(List<RoadReport> alerts) {
    return alerts.where((alert) {
      final hasPosition = alert.latitude != 0 && alert.longitude != 0;
      return hasPosition && alert.isActive && alert.status != 'deleted';
    }).toList();
  }

  void _openMap(List<RoadReport> alerts) {
    final mapAlerts = _mapAlerts(alerts);
    if (mapAlerts.isEmpty) {
      Setting.showMessage(
        'login_info'.tr,
        'Aucune alerte active ou prise en charge a afficher sur la carte.',
      );
      return;
    }

    Get.to(
      () => AlertsMapScreen(
        alerts: mapAlerts,
        formatType: _formatType,
        formatDate: _formatDate,
        formatStatus: _formatStatus,
        severityColor: _severityColor,
      ),
    );
  }

  Widget _buildFilters(List<RoadReport> alerts) {
    final types = _availableTypes(alerts);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterMenu(
              label: 'Etat',
              value: statusFilter,
              options: const {
                'all': 'Toutes',
                'active': 'Actives',
                'pending': 'Non prises en charge',
                'handled': 'Prises en charge',
                'expired': 'Expirees',
              },
              onChanged: (value) => setState(() => statusFilter = value),
            ),
            const SizedBox(width: 8),
            _FilterMenu(
              label: 'Type',
              value: typeFilter,
              options: {
                'all': 'Tous les types',
                for (final type in types) type: _formatType(type),
              },
              onChanged: (value) => setState(() => typeFilter = value),
            ),
            const SizedBox(width: 8),
            _FilterMenu(
              label: 'Gravite',
              value: severityFilter,
              options: const {
                'all': 'Toutes',
                'faible': 'Faible',
                'moyen': 'Moyen',
                'eleve': 'Eleve',
              },
              onChanged: (value) => setState(() => severityFilter = value),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(RoadReport alert) {
    final color = _severityColor(alert.severity);
    final currentUserId = Setting.userCtrl.user.value.key;
    final isAdmin = Setting.userCtrl.user.value.is_admin == true;
    final isHandled = alert.status == 'handled';
    final canVote = alert.isActive && alert.id != null && currentUserId != null;
    final hasConfirmed =
        currentUserId != null && alert.confirmedBy.contains(currentUserId);
    final hasRefuted =
        currentUserId != null && alert.refutedBy.contains(currentUserId);

    Get.bottomSheet(
      Container(
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusBottomSheet),
          ),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.triangleAlert,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatType(alert.type),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          _StatusPill(
                            label: _formatStatus(alert.status),
                            color:
                                isHandled
                                    ? AppColors.success
                                    : AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: AppColors.textMuted,
                      ),
                      onPressed: _closeBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Informations principales',
                  children: [
                    _DetailRow(label: 'Type', value: _formatType(alert.type)),
                    _DetailRow(label: 'Gravite', value: alert.severity),
                    _DetailRow(
                      label: 'Etat',
                      value:
                          '${_formatStatus(alert.status)} - ${alert.isActive ? 'Active' : 'Inactive'}',
                    ),
                    _DetailRow(
                      label: 'Date emission',
                      value: _formatDate(alert.createdAt),
                    ),
                    _DetailRow(
                      label: 'Expiration',
                      value: _formatDate(alert.expiresAt),
                    ),
                    _DetailRow(
                      label: 'Rayon',
                      value: '${alert.radiusMeters.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Localisation',
                  children: [
                    _DetailRow(
                      label: 'Reference',
                      value: _formatLocationReference(alert),
                    ),
                    _DetailRow(
                      label: 'Distance',
                      value: _formatDistanceFromCurrent(alert),
                    ),
                    _DetailRow(
                      label: 'Latitude',
                      value: alert.latitude.toStringAsFixed(6),
                    ),
                    _DetailRow(
                      label: 'Longitude',
                      value: alert.longitude.toStringAsFixed(6),
                    ),
                    _DetailRow(
                      label: 'Segment',
                      value: alert.segmentId ?? 'Non rattache',
                    ),
                    _DetailRow(
                      label: 'Route',
                      value: alert.routeId ?? 'Non rattachee',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Fiabilite collaborative',
                  children: [
                    _DetailRow(
                      label: 'Confirmations',
                      value: '${alert.confirmationCount}',
                    ),
                    _DetailRow(
                      label: 'Refutations',
                      value: '${alert.refutationCount}',
                    ),
                    _DetailRow(label: 'Source', value: alert.source),
                    _DetailRow(
                      label: 'Utilisateur',
                      value: alert.userId ?? 'Non renseigne',
                    ),
                  ],
                ),
                if (alert.comment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Commentaire',
                    children: [
                      Text(
                        alert.comment!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          canVote && !hasRefuted
                              ? () async {
                                _closeBottomSheet();
                                await _vote(alert, confirms: true);
                              }
                              : null,
                      icon: const Icon(LucideIcons.thumbsUp, size: 18),
                      label: Text(hasConfirmed ? 'Confirme' : 'Confirmer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canVote && !hasConfirmed
                              ? () async {
                                _closeBottomSheet();
                                await _vote(alert, confirms: false);
                              }
                              : null,
                      icon: const Icon(LucideIcons.thumbsDown, size: 18),
                      label: Text(hasRefuted ? 'Refute' : 'Refuter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed:
                            isHandled
                                ? null
                                : () async {
                                  _closeBottomSheet();
                                  await _markHandled(alert);
                                },
                        icon: const Icon(LucideIcons.circleCheck, size: 18),
                        label: const Text('Pris en charge'),
                      ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed: () async {
                          _closeBottomSheet();
                          await _deleteAlert(alert);
                        },
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(RoadReport alert) {
    final color = _severityColor(alert.severity);
    final isHandled = alert.status == 'handled';
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showAlertDetails(alert),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.triangleAlert, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatType(alert.type),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    _StatusPill(
                      label: _formatStatus(alert.status),
                      color: isHandled ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(alert.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatLocationReference(alert),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDistanceFromCurrent(alert),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoPill(
                      icon: LucideIcons.signalHigh,
                      label: alert.severity,
                      color: color,
                    ),
                    _VoteChip(
                      icon: LucideIcons.thumbsUp,
                      label: '${alert.confirmationCount}',
                      color: AppColors.success,
                      filled: alert.confirmationCount > 0,
                    ),
                    _VoteChip(
                      icon: LucideIcons.thumbsDown,
                      label: '${alert.refutationCount}',
                      color: AppColors.error,
                      filled: alert.refutationCount > 0,
                    ),
                  ],
                ),
                if (alert.comment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    alert.comment!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, widget.embedded ? 16 : 8, 12, 0),
              child: Row(
                children: [
                  if (!widget.embedded)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: Get.back,
                    ),
                  Expanded(
                    child: Text(
                      'Signalements',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                  FutureBuilder<List<RoadReport>>(
                    future: alertsFuture,
                    builder: (context, snapshot) {
                      return IconButton(
                        tooltip: 'Carte',
                        icon: const Icon(LucideIcons.map),
                        onPressed:
                            snapshot.hasData
                                ? () => _openMap(snapshot.data!)
                                : null,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<RoadReport>>(
                future: alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonList(count: 5);
                  }

                  final alerts = snapshot.data ?? const <RoadReport>[];
                  final filteredAlerts = _applyFilters(alerts);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildStats(alerts)),
                        if (alerts.isNotEmpty)
                          SliverToBoxAdapter(child: _buildFilters(alerts)),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Signalements (${filteredAlerts.length})',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                        if (filteredAlerts.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(
                              message:
                                  alerts.isEmpty
                                      ? 'Aucun signalement pour le moment.'
                                      : 'Aucun signalement ne correspond aux filtres.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            sliver: SliverList.separated(
                              itemCount: filteredAlerts.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildAlertCard(filteredAlerts[index]);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _FilterMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.entries
            .map(
              (entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      entry.key == value
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label : ${options[value] ?? value}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class AlertsMapScreen extends StatefulWidget {
  final List<RoadReport> alerts;
  final String Function(String type) formatType;
  final String Function(DateTime? date) formatDate;
  final String Function(String status) formatStatus;
  final Color Function(String severity) severityColor;

  const AlertsMapScreen({
    super.key,
    required this.alerts,
    required this.formatType,
    required this.formatDate,
    required this.formatStatus,
    required this.severityColor,
  });

  @override
  State<AlertsMapScreen> createState() => _AlertsMapScreenState();
}

class _AlertsMapScreenState extends State<AlertsMapScreen> {
  GoogleMapController? mapController;
  bool canShowUserLocation = false;
  bool trafficEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      canShowUserLocation =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  void _toggleTraffic() {
    setState(() => trafficEnabled = !trafficEnabled);
    Setting.showMessage(
      'Trafic',
      trafficEnabled
          ? 'Couche des embouteillages activee.'
          : 'Couche des embouteillages masquee.',
    );
  }

  String _formatLocationReference(RoadReport alert) {
    final label = alert.locationLabel?.trim();
    final address = alert.locationAddress?.trim();
    final segment = alert.segmentId?.trim();
    final route = alert.routeId?.trim();
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

  LatLngBounds get _bounds {
    final latitudes = widget.alerts.map((alert) => alert.latitude).toList();
    final longitudes = widget.alerts.map((alert) => alert.longitude).toList();
    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLng = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

    if (minLat == maxLat && minLng == maxLng) {
      const delta = 0.01;
      return LatLngBounds(
        southwest: LatLng(minLat - delta, minLng - delta),
        northeast: LatLng(maxLat + delta, maxLng + delta),
      );
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLng get _center {
    final bounds = _bounds;
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  Set<Marker> get _markers {
    return widget.alerts.map((alert) {
      final isHandled = alert.status == 'handled';
      final color =
          isHandled ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange;
      final statusLabel = isHandled ? 'Prise en charge' : 'Active';

      return Marker(
        markerId: MarkerId(alert.id ?? '${alert.latitude}_${alert.longitude}'),
        position: LatLng(alert.latitude, alert.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(
          title: '${widget.formatType(alert.type)} - $statusLabel',
          snippet: _formatLocationReference(alert),
          onTap: () => _showMapAlertDetails(alert),
        ),
        onTap: () => _showMapAlertDetails(alert),
      );
    }).toSet();
  }

  void _fitBounds() {
    final controller = mapController;
    if (controller == null) {
      return;
    }
    controller.animateCamera(CameraUpdate.newLatLngBounds(_bounds, 70));
  }

  void _showMapAlertDetails(RoadReport alert) {
    final isHandled = alert.status == 'handled';
    final statusColor =
        isHandled ? const Color(0xFF2E7D32) : const Color(0xFFC97A00);
    final severityColor = widget.severityColor(alert.severity);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusBottomSheet),
          ),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.triangleAlert,
                      color: severityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formatType(alert.type),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHandled ? 'Prise en charge' : 'Active',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
                    onPressed: () {
                      Navigator.of(
                        Get.overlayContext ?? context,
                        rootNavigator: true,
                      ).maybePop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MapDetailRow(label: 'Gravite', value: alert.severity),
              _MapDetailRow(
                label: 'Reference',
                value: _formatLocationReference(alert),
              ),
              _MapDetailRow(
                label: 'Date',
                value: widget.formatDate(alert.createdAt),
              ),
              _MapDetailRow(
                label: 'Expiration',
                value: widget.formatDate(alert.expiresAt),
              ),
              _MapDetailRow(
                label: 'Position',
                value:
                    '${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _VoteChip(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '${alert.confirmationCount}',
                    color: const Color(0xFF2E7D32),
                    filled: alert.confirmationCount > 0,
                  ),
                  const SizedBox(width: 8),
                  _VoteChip(
                    icon: Icons.thumb_down_alt_outlined,
                    label: '${alert.refutationCount}',
                    color: const Color(0xFFC62828),
                    filled: alert.refutationCount > 0,
                  ),
                ],
              ),
              if (alert.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  alert.comment!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Carte des signalements'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip:
                trafficEnabled
                    ? 'Masquer les embouteillages'
                    : 'Afficher les embouteillages',
            icon: Icon(
              LucideIcons.trafficCone,
              color: trafficEnabled ? AppColors.warning : AppColors.textMuted,
            ),
            onPressed: _toggleTraffic,
          ),
          IconButton(
            tooltip: 'Recentrer',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitBounds,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            trafficEnabled: trafficEnabled,
            onMapCreated: (controller) {
              mapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
            },
            myLocationEnabled: canShowUserLocation,
            myLocationButtonEnabled: canShowUserLocation,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _MapLegendItem(
                    color: const Color(0xFFFF9800),
                    label: 'Active',
                    count:
                        widget.alerts
                            .where((alert) => alert.status != 'handled')
                            .length,
                  ),
                  _MapLegendItem(
                    color: const Color(0xFF2E7D32),
                    label: 'Prise en charge',
                    count:
                        widget.alerts
                            .where((alert) => alert.status == 'handled')
                            .length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _MapLegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MapDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _MapDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _AlertStats {
  final int total;
  final int active;
  final int handled;
  final int expired;
  final int confirmations;
  final int refutations;
  final String topType;
  final String dominantSeverity;

  const _AlertStats({
    required this.total,
    required this.active,
    required this.handled,
    required this.expired,
    required this.confirmations,
    required this.refutations,
    required this.topType,
    required this.dominantSeverity,
  });
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _VoteChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
