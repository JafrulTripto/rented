import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).fetchStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              dashboardState.when(
                data: (stats) => _buildDashboardContent(context, stats, theme),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Pulse',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          'Overview of your rental business',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardStats stats,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatCards(stats, theme),
        const SizedBox(height: 24),
        _buildCollectionProgress(stats, theme),
        const SizedBox(height: 24),
        _buildQuickActions(context, theme),
        const SizedBox(height: 24),
        _buildNeedsAttentionList(context, stats, theme),
      ],
    );
  }

  Widget _buildStatCards(DashboardStats stats, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Revenue',
            '৳${NumberFormat.compact().format(stats.totalRevenue)}',
            Icons.attach_money_rounded,
            Colors.green,
            theme,
            subtitle: 'This Month',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Dues',
            '৳${NumberFormat.compact().format(stats.totalDue)}',
            Icons.warning_amber_rounded,
            Colors.orange,
            theme,
            subtitle: 'Total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Occupancy',
            '${stats.occupiedFlats}/${stats.totalFlats}',
            Icons.home_work_rounded,
            Colors.blue,
            theme,
            subtitle: 'Flats',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionProgress(DashboardStats stats, ThemeData theme) {
    if (stats.occupiedFlats == 0) return const SizedBox.shrink();

    final progress = stats.collectedCount / stats.occupiedFlats;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Status',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.collectedCount} of ${stats.occupiedFlats} flats paid this month',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              context,
              'Add Rent',
              Icons.receipt_long,
              () => context.push('/tenants'),
              theme,
            ), // Go to tenants to pick who to pay
            _buildActionButton(
              context,
              'New Tenant',
              Icons.person_add,
              () => context.push('/add-tenant'),
              theme,
            ),
            _buildActionButton(
              context,
              'New House',
              Icons.add_home_work,
              () => context.push('/houses'),
              theme,
            ),
            _buildActionButton(
              context,
              'All Dues',
              Icons.warning_amber,
              () => context.push('/tenants?filter=due'),
              theme,
            ), // Placeholder route
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsAttentionList(
    BuildContext context,
    DashboardStats stats,
    ThemeData theme,
  ) {
    if (stats.topDues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            Text(
              "All Clear!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "No pending dues found.",
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs Attention',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/tenants'),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...stats.topDues.map(
          (due) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color:
                  theme.cardTheme.color ??
                  theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                child: Icon(
                  Icons.priority_high,
                  color: theme.colorScheme.error,
                  size: 18,
                ),
              ),
              title: Text(
                due.tenantName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Flat ${due.flatNo} • ${due.month ?? "Multiple Months"}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: Text(
                '৳${due.dueAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                context.push('/rents/${due.tenantId}');
              },
            ),
          ),
        ),
      ],
    );
  }
}
