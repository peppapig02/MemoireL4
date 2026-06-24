import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key});

  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  static const _carNameKey = 'car_name';
  static const _carModeKey = 'car_mode';

  final _storage = GetStorage(Setting.storageName);
  final _carNameController = TextEditingController();
  late String _selectedMode;
  late Future<_CarDashboardData> _dashboardFuture;

  final List<String> _drivingModes = const [
    'car_mode_city',
    'car_mode_long',
    'car_mode_taxi',
    'car_mode_delivery',
  ];

  @override
  void initState() {
    super.initState();
    final savedCarName = _storage.read(_carNameKey) as String?;
    _carNameController.text =
        savedCarName?.trim().isNotEmpty == true
            ? savedCarName!
            : 'car_default_name'.tr;
    _selectedMode =
        (_storage.read(_carModeKey) as String?) ?? _drivingModes.first;
    _dashboardFuture = _loadDashboard();
  }

  @override
  void dispose() {
    _carNameController.dispose();
    super.dispose();
  }

  Future<_CarDashboardData> _loadDashboard() async {
    final userId = Setting.userCtrl.user.value.key;
    if (userId == null || userId.isEmpty) {
      return const _CarDashboardData();
    }

    final tripService = TripHistoryService(collection: Setting.fTripHistory);
    final roadReportService = RoadReportService(
      collection: Setting.fRoadReports,
    );

    final trips = await tripService.getTripHistoryForUser(userId, limit: 5);
    final reports = await roadReportService.getRoadReportsForUser(
      userId,
      limit: 5,
    );

    return _CarDashboardData(trips: trips, reports: reports);
  }

  Future<void> _savePreferences() async {
    final name = _carNameController.text.trim();
    if (name.isEmpty) {
      Setting.showMessage('login_error'.tr, 'car_name_required'.tr, Colors.red);
      return;
    }

    await _storage.write(_carNameKey, name);
    await _storage.write(_carModeKey, _selectedMode);

    if (!mounted) return;

    setState(() {});
    Setting.showMessage(
      'login_verification'.tr,
      'car_save_success'.tr,
      Colors.green,
    );
  }

  String _formatTripTitle(TripHistory trip) {
    final start =
        trip.originLabel?.trim().isNotEmpty == true
            ? trip.originLabel!
            : 'car_start'.tr;
    final destination =
        trip.destinationLabel?.trim().isNotEmpty == true
            ? trip.destinationLabel!
            : 'car_destination'.tr;
    return '$start -> $destination';
  }

  String _formatTripMeta(TripHistory trip) {
    final distance = trip.distance.toStringAsFixed(1);
    final duration = trip.duration.toStringAsFixed(0);
    final warnings = trip.warnings.length;
    return '$distance km - $duration min - $warnings ${'car_alerts'.tr}';
  }

  String _formatReportMeta(RoadReport report) {
    return '${_capitalize(report.type.replaceAll('_', ' '))} - ${_capitalize(report.severity)} - ${_capitalize(report.status)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'car_date_unknown'.tr;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a $hour:$minute';
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = Setting.userCtrl.user.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('car_title'.tr),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_CarDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const _CarDashboardData();
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B5D7A), Color(0xFF1792B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'car_driver_space'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _carNameController.text.trim(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.nom ?? 'car_default_driver'.tr} - ${_selectedMode.tr}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            label: 'car_recent_trips'.tr,
                            value: '${data.trips.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatChip(
                            label: 'car_reports'.tr,
                            value: '${data.reports.length}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'car_vehicle_preferences'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _carNameController,
                        decoration: InputDecoration(
                          labelText: 'car_vehicle_name'.tr,
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMode,
                        items:
                            _drivingModes
                                .map(
                                  (mode) => DropdownMenuItem<String>(
                                    value: mode,
                                    child: Text(mode.tr),
                                  ),
                                )
                                .toList(),
                        decoration: InputDecoration(
                          labelText: 'car_driving_mode'.tr,
                          prefixIcon: Icon(Icons.tune),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text('car_save'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'car_summary'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CarInfoRow(
                        label: 'car_driver'.tr,
                        value: user.nom ?? 'car_not_provided'.tr,
                      ),
                      _CarInfoRow(
                        label: 'car_email'.tr,
                        value: user.email ?? 'car_not_provided'.tr,
                      ),
                      _CarInfoRow(
                        label: 'car_last_login'.tr,
                        value: user.date_connexion ?? 'car_not_available'.tr,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'car_recent_trips'.tr,
                isLoading: isLoading,
                emptyMessage: 'car_no_recent_trip'.tr,
                children:
                    data.trips
                        .map(
                          (trip) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE7F6FB),
                              child: Icon(
                                Icons.route,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(_formatTripTitle(trip)),
                            subtitle: Text(_formatTripMeta(trip)),
                            trailing: Text(
                              _formatDate(trip.createdAt),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'car_reports'.tr,
                isLoading: isLoading,
                emptyMessage: 'car_no_recent_report'.tr,
                children:
                    data.reports
                        .map(
                          (report) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFF3E6),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC97A00),
                              ),
                            ),
                            title: Text(_formatReportMeta(report)),
                            subtitle: Text(
                              report.comment?.trim().isNotEmpty == true
                                  ? report.comment!
                                  : 'car_no_comment'.tr,
                            ),
                            trailing: Text(
                              _formatDate(report.createdAt),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CarDashboardData {
  final List<TripHistory> trips;
  final List<RoadReport> reports;

  const _CarDashboardData({this.trips = const [], this.reports = const []});
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String emptyMessage;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isLoading,
    required this.emptyMessage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (children.isEmpty)
              Text(emptyMessage, style: const TextStyle(color: Colors.black54))
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _CarInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CarInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
