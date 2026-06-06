import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final RoadReportService roadReportService;
  late Future<List<RoadReport>> alertsFuture;
  String statusFilter = 'all';
  String typeFilter = 'all';
  String severityFilter = 'all';

  @override
  void initState() {
    super.initState();
    roadReportService = RoadReportService(collection: Setting.fRoadReports);
    alertsFuture = roadReportService.getRecentRoadReports(limit: 100);
  }

  Future<void> _refresh() async {
    setState(() {
      alertsFuture = roadReportService.getRecentRoadReports(limit: 100);
    });
    await alertsFuture;
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
        return const Color(0xFFE53935);
      case 'moyen':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4CAF50);
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatTile(
                icon: Icons.warning_amber_rounded,
                label: 'Total',
                value: '${stats.total}',
                color: AppColors.primary,
              ),
              _StatTile(
                icon: Icons.radar,
                label: 'Actives',
                value: '${stats.active}',
                color: const Color(0xFFE53935),
              ),
              _StatTile(
                icon: Icons.check_circle_outline,
                label: 'Prises en charge',
                value: '${stats.handled}',
                color: const Color(0xFF2E7D32),
              ),
              _StatTile(
                icon: Icons.schedule,
                label: 'Expirees',
                value: '${stats.expired}',
                color: const Color(0xFF6B7280),
              ),
              _StatTile(
                icon: Icons.category_outlined,
                label: 'Type frequent',
                value: _formatType(stats.topType),
                color: const Color(0xFF1565C0),
              ),
              _StatTile(
                icon: Icons.priority_high,
                label: 'Gravite dominante',
                value: stats.dominantSeverity,
                color: _severityColor(stats.dominantSeverity),
              ),
              _StatTile(
                icon: Icons.thumb_up_alt_outlined,
                label: 'Confirmations',
                value: '${stats.confirmations}',
                color: const Color(0xFF2E7D32),
              ),
              _StatTile(
                icon: Icons.thumb_down_alt_outlined,
                label: 'Refutations',
                value: '${stats.refutations}',
                color: const Color(0xFFC62828),
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
      final hasPosition = alert.latitude != 0 || alert.longitude != 0;
      final hasVisibleStatus = alert.isActive || alert.status == 'handled';
      return hasPosition && hasVisibleStatus && alert.status != 'deleted';
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFFF7F8FA),
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
              onChanged: (value) {
                setState(() {
                  statusFilter = value;
                });
              },
            ),
            const SizedBox(width: 8),
            _FilterMenu(
              label: 'Type',
              value: typeFilter,
              options: {
                'all': 'Tous les types',
                for (final type in types) type: _formatType(type),
              },
              onChanged: (value) {
                setState(() {
                  typeFilter = value;
                });
              },
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
              onChanged: (value) {
                setState(() {
                  severityFilter = value;
                });
              },
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                      backgroundColor: color.withValues(alpha: 0.14),
                      child: Icon(Icons.warning_amber_rounded, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatType(alert.type),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatStatus(alert.status)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: Get.back,
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
                    children: [Text(alert.comment!)],
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          canVote
                              ? () async {
                                Get.back();
                                await _vote(alert, confirms: true);
                              }
                              : null,
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      label: Text(hasConfirmed ? 'Confirme' : 'Confirmer'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canVote
                              ? () async {
                                Get.back();
                                await _vote(alert, confirms: false);
                              }
                              : null,
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      label: Text(hasRefuted ? 'Refute' : 'Refuter'),
                    ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed:
                            isHandled
                                ? null
                                : () async {
                                  Get.back();
                                  await _markHandled(alert);
                                },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Pris en charge'),
                      ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed: () async {
                          Get.back();
                          await _deleteAlert(alert);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
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
    final currentUserId = Setting.userCtrl.user.value.key;
    final isAdmin = Setting.userCtrl.user.value.is_admin == true;
    final canVote = alert.isActive && alert.id != null && currentUserId != null;
    final hasConfirmed =
        currentUserId != null && alert.confirmedBy.contains(currentUserId);
    final hasRefuted =
        currentUserId != null && alert.refutedBy.contains(currentUserId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAlertDetails(alert),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.14),
                    child: Icon(Icons.warning_amber_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatType(alert.type),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_formatDate(alert.createdAt)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHandled
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(alert.status),
                      style: TextStyle(
                        color:
                            isHandled
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF8A5200),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Gravite : ${alert.severity}'),
              const SizedBox(height: 6),
              Row(
                children: [
                  _VoteChip(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '${alert.confirmationCount}',
                    color: const Color(0xFF2E7D32),
                    filled: hasConfirmed,
                  ),
                  const SizedBox(width: 8),
                  _VoteChip(
                    icon: Icons.thumb_down_alt_outlined,
                    label: '${alert.refutationCount}',
                    color: const Color(0xFFC62828),
                    filled: hasRefuted,
                  ),
                ],
              ),
              Text(
                'Expiration : ${_formatDate(alert.expiresAt)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (alert.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  alert.comment!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (alert.id != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          canVote ? () => _vote(alert, confirms: true) : null,
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      label: Text(hasConfirmed ? 'Confirme' : 'Confirmer'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canVote ? () => _vote(alert, confirms: false) : null,
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      label: Text(hasRefuted ? 'Refute' : 'Refuter'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showAlertDetails(alert),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed: isHandled ? null : () => _markHandled(alert),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Pris en charge'),
                      ),
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed: () => _deleteAlert(alert),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
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
      appBar: AppBar(
        title: const Text('Alertes route'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          FutureBuilder<List<RoadReport>>(
            future: alertsFuture,
            builder: (context, snapshot) {
              return IconButton(
                tooltip: 'Carte',
                icon: const Icon(Icons.map_outlined),
                onPressed:
                    snapshot.hasData ? () => _openMap(snapshot.data!) : null,
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<RoadReport>>(
        future: alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data ?? const <RoadReport>[];
          if (alerts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune alerte active pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final filteredAlerts = _applyFilters(alerts);

          return Column(
            children: [
              _buildStats(alerts),
              _buildFilters(alerts),
              Expanded(
                child:
                    filteredAlerts.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aucune alerte ne correspond aux filtres.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAlerts.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final alert = filteredAlerts[index];
                              return _buildAlertCard(alert);
                            },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label : ${options[value] ?? value}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18),
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
          snippet:
              '${alert.severity} | +${alert.confirmationCount} / -${alert.refutationCount}',
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
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: severityColor.withValues(alpha: 0.14),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: severityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.formatType(alert.type),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                ],
              ),
              const SizedBox(height: 14),
              _MapDetailRow(label: 'Gravite', value: alert.severity),
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
                Text(alert.comment!),
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
      appBar: AppBar(
        title: const Text('Carte des alertes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
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
            onMapCreated: (controller) {
              mapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
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
      width: 160,
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  maxLines: 2,
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
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: filled ? color : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
