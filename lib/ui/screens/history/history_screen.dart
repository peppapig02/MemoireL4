import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/fade_slide.dart';
import 'package:botroad/ui/animations/skeleton.dart';
import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:botroad/ui/controllers/active_route_controller.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/app_card.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Historique unifié — conversations IA + trajets.
class HistoryScreen extends StatefulWidget {
  final bool embedded;

  const HistoryScreen({super.key, this.embedded = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<ConversationsModel> _conversations = [];
  List<TripHistory> _trips = [];
  bool _loadingConversations = true;
  bool _loadingTrips = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadConversations(), _loadTrips()]);
  }

  Future<void> _loadConversations() async {
    setState(() => _loadingConversations = true);
    try {
      final list = await Setting.conversationsCtrl.getConversationsOfUser(
        Setting.userCtrl.user.value.key!,
        limit: 50,
      );
      if (list != null && mounted) setState(() => _conversations = list);
    } finally {
      if (mounted) setState(() => _loadingConversations = false);
    }
  }

  Future<void> _loadTrips() async {
    setState(() => _loadingTrips = true);
    try {
      final userId = Setting.userCtrl.user.value.key;
      if (userId != null) {
        final service = TripHistoryService(collection: Setting.fTripHistory);
        final trips = await service.getTripHistoryForUser(userId, limit: 50);
        if (mounted) setState(() => _trips = trips);
      }
    } finally {
      if (mounted) setState(() => _loadingTrips = false);
    }
  }

  Future<void> _deleteConversation(ConversationsModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Supprimer la conversation'),
        content: Text(
          'Supprimer "${c.libelle ?? 'cette conversation'}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await Setting.conversationsCtrl.deleteConversation(c.key!);
    if (mounted) {
      if (ok) {
        setState(() => _conversations.removeWhere((x) => x.key == c.key));
        Setting.showMessage('Conversation supprimée', '', AppColors.success);
      } else {
        Setting.showMessage(
          'Erreur',
          'Impossible de supprimer la conversation.',
          Colors.red,
        );
      }
    }
  }

  void _viewTripOnMap(TripHistory trip) {
    final points = _buildPoints(trip);
    final route = RoutesModel(
      nom: '${trip.originLabel ?? 'Départ'} → ${trip.destinationLabel ?? 'Destination'}',
      points: points,
      segments: trip.segments.map((s) => s.toJson()).toList(),
      warnings: trip.warnings,
      mode: 'fast',
    );

    if (Get.isRegistered<ActiveRouteController>()) {
      Get.find<ActiveRouteController>().setActiveRoute(route);
    }
    switchMainTab(1);
  }

  String _buildPoints(TripHistory trip) {
    if (trip.segments.isEmpty) {
      return '${trip.originLat},${trip.originLng}|${trip.destinationLat},${trip.destinationLng}';
    }
    final buf = StringBuffer();
    for (int i = 0; i < trip.segments.length; i++) {
      final seg = trip.segments[i];
      if (i == 0) buf.write('${seg.startLat},${seg.startLng}');
      buf.write('|${seg.endLat},${seg.endLng}');
    }
    return buf.toString();
  }

  List<ConversationsModel> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final q = _searchQuery.toLowerCase();
    return _conversations.where((c) {
      return (c.libelle ?? '').toLowerCase().contains(q) ||
          _formatDate(c.date_create).toLowerCase().contains(q);
    }).toList();
  }

  List<TripHistory> get _filteredTrips {
    if (_searchQuery.isEmpty) return _trips;
    final q = _searchQuery.toLowerCase();
    return _trips.where((t) {
      final origin = (t.originLabel ?? '').toLowerCase();
      final dest = (t.destinationLabel ?? '').toLowerCase();
      return origin.contains(q) || dest.contains(q);
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTripDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, widget.embedded ? 16 : 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded)
                    Text(
                      'Historique',
                      style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                  if (widget.embedded) const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(LucideIcons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  _PillTabBar(
                    controller: _tabController,
                    labels: const ['Conversations', 'Trajets'],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ConversationsTab(
                    loading: _loadingConversations,
                    items: _filteredConversations,
                    formatDate: _formatDate,
                    onRefresh: _loadConversations,
                    onDelete: _deleteConversation,
                  ),
                  _TripsTab(
                    loading: _loadingTrips,
                    items: _filteredTrips,
                    formatDate: _formatTripDate,
                    onRefresh: _loadTrips,
                    onViewOnMap: _viewTripOnMap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsTab extends StatelessWidget {
  final bool loading;
  final List<ConversationsModel> items;
  final String Function(String?) formatDate;
  final Future<void> Function() onRefresh;
  final Future<void> Function(ConversationsModel) onDelete;

  const _ConversationsTab({
    required this.loading,
    required this.items,
    required this.formatDate,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonList(count: 5);
    }
    if (items.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.messageCircle,
        message: 'Aucune conversation',
        subtitle: 'Vos échanges avec l\'assistant apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final c = items[index];
          return FadeSlide(
            key: ValueKey(c.key),
            delay: Duration(milliseconds: index < 6 ? index * 55 : 0),
            child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey('d_${c.key}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                await onDelete(c);
                return false; // We handle list removal ourselves
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                onTap: () => Get.to(
                  () => AIChatScreen(conversation: c),
                  transition: Transition.fadeIn,
                  duration: AppAnimations.normal,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.libelle ?? 'Nouvelle conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(c.date_create),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => onDelete(c),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ),
            ),    // Padding
          );      // FadeSlide
        },
      ),
    );
  }
}

class _TripsTab extends StatelessWidget {
  final bool loading;
  final List<TripHistory> items;
  final String Function(DateTime?) formatDate;
  final Future<void> Function() onRefresh;
  final void Function(TripHistory) onViewOnMap;

  const _TripsTab({
    required this.loading,
    required this.items,
    required this.formatDate,
    required this.onRefresh,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonList(count: 5);
    }
    if (items.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.route,
        message: 'Aucun trajet',
        subtitle: 'Vos itinéraires précédents seront listés ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final trip = items[index];
          final origin = trip.originLabel ?? 'Départ';
          final dest = trip.destinationLabel ?? 'Destination';

          return FadeSlide(
            key: ValueKey(trip.id ?? index),
            delay: Duration(milliseconds: index < 6 ? index * 55 : 0),
            child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.route,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$origin → $dest',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.ruler,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.distance.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.duration.toStringAsFixed(0)} min',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (trip.warnings.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.triangleAlert,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.warnings.length} signalement${trip.warnings.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(trip.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => onViewOnMap(trip),
                      icon: const Icon(LucideIcons.map, size: 16),
                      label: const Text('Voir sur la carte'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),   // Padding
          );     // FadeSlide
        },
      ),
    );
  }
}

class _PillTabBar extends StatefulWidget {
  final TabController controller;
  final List<String> labels;

  const _PillTabBar({required this.controller, required this.labels});

  @override
  State<_PillTabBar> createState() => _PillTabBarState();
}

class _PillTabBarState extends State<_PillTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.controller.index;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTokens.borderRadiusButton,
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / widget.labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: AppAnimations.normal,
                curve: AppAnimations.enter,
                alignment: Alignment(
                  widget.labels.length == 1
                      ? 0
                      : -1 + 2 * activeIndex / (widget.labels.length - 1),
                  0,
                ),
                child: Container(
                  width: segmentWidth,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppTokens.borderRadiusButton,
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.labels.length, (index) {
                  final selected = index == activeIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.controller.animateTo(index),
                      child: Center(
                        child: Text(
                          widget.labels[index],
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
