import 'package:botroad/core/i18n/app_translations.dart';
import 'package:botroad/ui/animations/success_check.dart';
import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/ui/screens/alerts/alerts_screen.dart';
import 'package:botroad/controllers/theme_controller.dart';
import 'package:botroad/ui/animations/fade_slide.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/menu_item_tile.dart';
import 'package:botroad/ui/widgets/v2/primary_button.dart';
import 'package:botroad/ui/widgets/v2/section_header.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
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
    _selectedMode =
        (_storage.read(_carModeKey) as String?) ?? _drivingModes.first;
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
    final trips = await TripHistoryService(
      collection: Setting.fTripHistory,
    ).getTripHistoryForUser(userId, limit: 3);
    final reports = await RoadReportService(
      collection: Setting.fRoadReports,
    ).getRoadReportsForUser(userId, limit: 3);
    return _ProfileData(trips: trips, reports: reports);
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) return;
    final ok = await Setting.userCtrl.updateUser({'nom': _nameController.text});
    if (ok && mounted) {
      Get.back();
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
    if (!mounted) return;
    setState(() {});
    Get.back();
    showSuccessOverlay(context);
  }

  void _showEditProfileSheet() {
    Get.bottomSheet(
      _BottomSheetWrapper(
        title: 'profile_name'.tr,
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'profile_name'.tr,
                prefixIcon: const Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'profile_update'.tr,
              glowing: false,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showVehicleSheet() {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setS) => _BottomSheetWrapper(
          title: 'car_title'.tr,
          child: Column(
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
                initialValue: _selectedMode,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  labelText: 'car_driving_mode'.tr,
                  prefixIcon: const Icon(LucideIcons.settings),
                ),
                items: _drivingModes
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.tr)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setS(() => _selectedMode = v);
                    setState(() => _selectedMode = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'car_save'.tr,
                glowing: false,
                onPressed: _saveCarPrefs,
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showLanguageSheet() {
    final current = AppTranslations.codeFromLocale(
      Get.locale ?? AppTranslations.fallback,
    );
    Get.bottomSheet(
      _BottomSheetWrapper(
        title: 'drawer_choose_language'.tr,
        child: Column(
          children: [
            ('fr', 'language_french'.tr),
            ('en', 'language_english'.tr),
            ('ln', 'language_lingala'.tr),
            ('sw', 'language_swahili'.tr),
          ]
              .map(
                (e) => MenuItemTile(
                  icon: current == e.$1
                      ? LucideIcons.circleCheck
                      : LucideIcons.circle,
                  label: e.$2,
                  iconColor: current == e.$1
                      ? AppColors.primary
                      : AppColors.textMuted,
                  iconBackground: current == e.$1
                      ? AppColors.accentSoft
                      : AppColors.backgroundSecondary,
                  onTap: () async {
                    await AppTranslations.changeLocale(e.$1);
                    Get.back();
                    setState(() {});
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAboutSheet() {
    Get.bottomSheet(
      _BottomSheetWrapper(
        title: 'drawer_about'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'about_project_body'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'about_future_body'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'auth_version'.trParams({'version': Setting.version}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountInfoSheet(_ProfileData data) {
    final user = Setting.userCtrl.user.value;
    Get.bottomSheet(
      _BottomSheetWrapper(
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
    );
  }

  Widget _section(List<Widget> tiles) {
    return Container(
      decoration: AppTokens.cardDecoration(),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          final isLast = e.key == tiles.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 0,
                  color: AppColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Setting.userCtrl.user.value;
    final langCode = AppTranslations.codeFromLocale(
      Get.locale ?? AppTranslations.fallback,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_ProfileData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const _ProfileData();

          return CustomScrollView(
            slivers: [
              // ── Hero corail ────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  child: const Icon(
                                    LucideIcons.user,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.nom ?? 'Mon profil',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Stats chips
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _StatChip(
                                    label: 'car_recent_trips'.tr,
                                    value: '${data.trips.length}',
                                  ),
                                  const SizedBox(width: 12),
                                  _StatChip(
                                    label: 'car_reports'.tr,
                                    value: '${data.reports.length}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Courbe de transition
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sections ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Mon Compte
                    const SectionHeader(title: 'Mon Compte'),
                    const SizedBox(height: 12),
                    FadeSlide(
                      delay: Duration.zero,
                      child: _section([
                      MenuItemTile(
                        icon: LucideIcons.user,
                        label: 'Mon profil',
                        subtitle: user.nom ?? '',
                        onTap: _showEditProfileSheet,
                      ),
                      MenuItemTile(
                        icon: LucideIcons.car,
                        label: 'car_title'.tr,
                        subtitle: _carNameController.text,
                        onTap: _showVehicleSheet,
                      ),
                      MenuItemTile(
                        icon: LucideIcons.languages,
                        label: 'drawer_language'.tr,
                        subtitle: AppTranslations.labelFromCode(langCode),
                        onTap: _showLanguageSheet,
                      ),
                      MenuItemTile(
                        icon: LucideIcons.bell,
                        label: 'Notifications',
                        subtitle: 'Bientôt disponible',
                        trailing: Switch(
                          value: false,
                          onChanged: null,
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                      Obx(() {
                        final tc = Get.find<ThemeController>();
                        return MenuItemTile(
                          icon: tc.isDark.value
                              ? LucideIcons.moon
                              : LucideIcons.sun,
                          label: 'Thème',
                          subtitle: tc.isDark.value ? 'Mode sombre' : 'Mode clair',
                          trailing: Switch(
                            value: tc.isDark.value,
                            onChanged: (_) => tc.toggle(),
                            activeThumbColor: AppColors.primary,
                            activeTrackColor:
                                AppColors.primary.withValues(alpha: 0.25),
                          ),
                        );
                      }),
                    ]),      // _section
                    ),       // FadeSlide

                    const SizedBox(height: 24),

                    // Navigation
                    const SectionHeader(title: 'Navigation'),
                    const SizedBox(height: 12),
                    FadeSlide(
                      delay: const Duration(milliseconds: 80),
                      child: _section([
                      MenuItemTile(
                        icon: LucideIcons.triangleAlert,
                        label: 'Signalements',
                        subtitle: 'Consulter les alertes',
                        onTap: () => Get.to(() => const AlertsScreen()),
                      ),
                      MenuItemTile(
                        icon: LucideIcons.history,
                        label: 'Historique',
                        subtitle: '${data.trips.length} trajets récents',
                        onTap: () => switchMainTab(3),
                      ),
                    ]),   // _section
                    ),    // FadeSlide

                    const SizedBox(height: 24),

                    // Informations
                    SectionHeader(
                      title: 'profile_account_info'.tr,
                    ),
                    const SizedBox(height: 12),
                    FadeSlide(
                      delay: const Duration(milliseconds: 160),
                      child: _section([
                      MenuItemTile(
                        icon: LucideIcons.info,
                        label: 'drawer_about'.tr,
                        onTap: _showAboutSheet,
                      ),
                      MenuItemTile(
                        icon: LucideIcons.shieldCheck,
                        label: 'profile_account_info'.tr,
                        subtitle: user.is_active == true
                            ? 'profile_status_active'.tr
                            : 'profile_status_inactive'.tr,
                        onTap: () => _showAccountInfoSheet(data),
                      ),
                    ]),   // _section
                    ),    // FadeSlide

                    const SizedBox(height: 32),

                    // Déconnexion
                    PrimaryButton(
                      label: 'drawer_logout'.tr,
                      glowing: false,
                      onPressed: () => Setting.userCtrl.deconnectUser(),
                      icon: LucideIcons.logOut,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Bottom sheet wrapper ───────────────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keyboard inset outside the Container so it pushes the sheet up
      // rather than expanding the Column inside it.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            // ClampingScrollPhysics prevents the StretchingOverscrollIndicator
            // from firing setState during layout when the sheet resizes.
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _ProfileData {
  final List<TripHistory> trips;
  final List<RoadReport> reports;
  const _ProfileData({this.trips = const [], this.reports = const []});
}
