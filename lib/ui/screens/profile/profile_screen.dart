import 'package:botroad/core/i18n/app_translations.dart';
import 'package:botroad/ui/animations/accordion_section.dart';
import 'package:botroad/ui/animations/success_check.dart';
import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/app_card.dart';
import 'package:botroad/ui/widgets/v2/primary_button.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _carNameKey = 'car_name';
  static const _carModeKey = 'car_mode';

  final _storage = GetStorage(Setting.storageName);
  final _nameController = TextEditingController();
  final _carNameController = TextEditingController();
  late String _selectedMode;
  Future<_ProfileData>? _dataFuture;

  final _drivingModes = const [
    'car_mode_city',
    'car_mode_long',
    'car_mode_taxi',
    'car_mode_delivery',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = Setting.userCtrl.user.value.nom ?? '';
    final savedCar = _storage.read(_carNameKey) as String?;
    _carNameController.text =
        savedCar?.trim().isNotEmpty == true ? savedCar! : 'car_default_name'.tr;
    _selectedMode = (_storage.read(_carModeKey) as String?) ?? _drivingModes.first;
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carNameController.dispose();
    super.dispose();
  }

  Future<_ProfileData> _loadData() async {
    final userId = Setting.userCtrl.user.value.key;
    if (userId == null) return const _ProfileData();

    final tripService = TripHistoryService(collection: Setting.fTripHistory);
    final reportService = RoadReportService(collection: Setting.fRoadReports);
    final trips = await tripService.getTripHistoryForUser(userId, limit: 3);
    final reports = await reportService.getRoadReportsForUser(userId, limit: 3);
    return _ProfileData(trips: trips, reports: reports);
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) return;
    final ok = await Setting.userCtrl.updateUser({'nom': _nameController.text});
    if (ok && mounted) {
      showSuccessOverlay(context);
    }
  }

  Future<void> _saveCarPrefs() async {
    final name = _carNameController.text.trim();
    if (name.isEmpty) {
      Setting.showMessage('login_error'.tr, 'car_name_required'.tr, Colors.red);
      return;
    }
    await _storage.write(_carNameKey, name);
    await _storage.write(_carModeKey, _selectedMode);
    if (mounted) setState(() {});
    showSuccessOverlay(context);
  }

  void _showLanguageSheet() {
    final current = AppTranslations.codeFromLocale(
      Get.locale ?? AppTranslations.fallback,
    );
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('drawer_choose_language'.tr,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...[
              ('fr', 'language_french'.tr),
              ('en', 'language_english'.tr),
              ('ln', 'language_lingala'.tr),
              ('sw', 'language_swahili'.tr),
            ].map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  current == e.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(e.$2),
                onTap: () async {
                  await AppTranslations.changeLocale(e.$1);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Setting.userCtrl.user.value;
    final theme = Theme.of(context);
    final langCode = AppTranslations.codeFromLocale(
      Get.locale ?? AppTranslations.fallback,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _ProfileData();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, widget.embedded ? 16 : 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded)
                    Text('Profil',
                        style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                  if (widget.embedded) const SizedBox(height: 20),

                  // Carte utilisateur
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            boxShadow: AppTokens.glowAccent(opacity: 0.1),
                          ),
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.background,
                            child: Icon(
                              CupertinoIcons.person_fill,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.nom ?? 'BotRoad',
                                  style: theme.textTheme.titleMedium),
                              Text(user.email ?? '',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'profile_name'.tr,
                            prefixIcon: const Icon(LucideIcons.user),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'profile_update'.tr,
                          glowing: false,
                          onPressed: _saveProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mon véhicule
                  AppCard(
                    child: AccordionSection(
                      title: 'car_title'.tr,
                      initiallyExpanded: true,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _carNameController,
                          decoration: InputDecoration(
                            labelText: 'car_vehicle_name'.tr,
                            prefixIcon: const Icon(LucideIcons.car),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedMode,
                          dropdownColor: AppColors.surface,
                          items: _drivingModes
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.tr),
                                  ))
                              .toList(),
                          decoration: InputDecoration(
                            labelText: 'car_driving_mode'.tr,
                            prefixIcon: const Icon(LucideIcons.settings),
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedMode = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Stat(label: 'car_recent_trips'.tr,
                                value: '${data.trips.length}'),
                            const SizedBox(width: 12),
                            _Stat(label: 'car_reports'.tr,
                                value: '${data.reports.length}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'car_save'.tr,
                          glowing: false,
                          onPressed: _saveCarPrefs,
                        ),
                      ],
                    ),
                    ),
                  ),
                  if (data.trips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('car_recent_trips'.tr,
                              style: theme.textTheme.titleMedium),
                          ...data.trips.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${t.originLabel ?? 'car_start'.tr} → ${t.destinationLabel ?? 'car_destination'.tr}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (data.reports.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('car_reports'.tr,
                              style: theme.textTheme.titleMedium),
                          ...data.reports.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${r.type} · ${r.severity}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Préférences
                  AppCard(
                    child: AccordionSection(
                      title: 'Préférences',
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.languages),
                            title: Text('drawer_language'.tr),
                            subtitle: Text(AppTranslations.labelFromCode(langCode)),
                            trailing: const Icon(LucideIcons.chevronRight, size: 18),
                            onTap: _showLanguageSheet,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.bell),
                            title: const Text('Notifications'),
                            subtitle: const Text('Bientôt disponible'),
                            trailing: Switch(
                              value: false,
                              onChanged: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informations compte
                  AppCard(
                    child: AccordionSection(
                      title: 'profile_account_info'.tr,
                      child: Column(
                        children: [
                          _InfoRow('profile_creation_date'.tr,
                              user.date_create ?? 'profile_not_available'.tr),
                          _InfoRow('profile_last_login'.tr,
                              user.date_connexion ?? 'profile_not_available'.tr),
                          _InfoRow(
                            'profile_account_status'.tr,
                            user.is_active == true
                                ? 'profile_status_active'.tr
                                : 'profile_status_inactive'.tr,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // À propos
                  AppCard(
                    child: AccordionSection(
                      title: 'drawer_about'.tr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('about_project_body'.tr,
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Text('about_future_body'.tr,
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Text(
                            'auth_version'.trParams({'version': Setting.version}),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'drawer_logout'.tr,
                    glowing: false,
                    onPressed: () => Setting.userCtrl.deconnectUser(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileData {
  final List<TripHistory> trips;
  final List<RoadReport> reports;

  const _ProfileData({this.trips = const [], this.reports = const []});
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    )),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
