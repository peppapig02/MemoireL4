import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/skeleton.dart';
import 'package:botroad/core/models/trip_history.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/widgets/v2/app_card.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/cupertino.dart';
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
      if (list != null) setState(() => _conversations = list);
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
        setState(() => _trips = trips);
      }
    } finally {
      if (mounted) setState(() => _loadingTrips = false);
    }
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
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    dividerColor: AppColors.divider,
                    tabs: const [
                      Tab(text: 'Conversations'),
                      Tab(text: 'Trajets'),
                    ],
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
                  ),
                  _TripsTab(
                    loading: _loadingTrips,
                    items: _filteredTrips,
                    formatDate: _formatTripDate,
                    onRefresh: _loadTrips,
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

  const _ConversationsTab({
    required this.loading,
    required this.items,
    required this.formatDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonList(count: 5);
    }
    if (items.isEmpty) {
      return _EmptyState(
        icon: CupertinoIcons.chat_bubble_2,
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              onTap: () => Get.to(
                () => AIChatScreen(conversation: c),
                transition: Transition.fadeIn,
                duration: AppAnimations.normal,
              ),
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
          );
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

  const _TripsTab({
    required this.loading,
    required this.items,
    required this.formatDate,
    required this.onRefresh,
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$origin → $dest',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${trip.distance.toStringAsFixed(1)} km · ${trip.duration.toStringAsFixed(0)} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(trip.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
