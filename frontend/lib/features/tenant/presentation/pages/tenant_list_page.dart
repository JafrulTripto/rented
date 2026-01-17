import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/tenant/presentation/providers/tenant_provider.dart';
import 'package:frontend/features/house/presentation/providers/house_provider.dart';

class TenantListPage extends ConsumerStatefulWidget {
  final bool showDuesOnly;
  const TenantListPage({this.showDuesOnly = false, super.key});

  @override
  ConsumerState<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends ConsumerState<TenantListPage> {
  late bool _showDuesOnly;

  @override
  void initState() {
    super.initState();
    _showDuesOnly = widget.showDuesOnly;
  }

  @override
  void didUpdateWidget(covariant TenantListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showDuesOnly != widget.showDuesOnly) {
      _showDuesOnly = widget.showDuesOnly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = ref.watch(tenantProvider);
    final houseState = ref.watch(houseProvider);
    final theme = Theme.of(context);

    final tenants = _showDuesOnly
        ? tenantState.tenants.where((t) => t.dueAmount > 0).toList()
        : tenantState.tenants;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: houseState.houses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-tenant'),
              label: const Text(
                'Add Tenant',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.person_add_rounded),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
      body: tenantState.isLoading || houseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tenantState.error != null
          ? Center(child: Text('Error: ${tenantState.error}'))
          : houseState.houses.isEmpty
          ? _buildEmptyHouses(context)
          : Column(
              children: [
                if (tenants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${tenants.length} ${_showDuesOnly ? 'Dues' : 'Tenants'}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: tenants.isEmpty
                      ? _buildEmptyTenants()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemCount: tenants.length,
                          itemBuilder: (context, index) {
                            final tenant = tenants[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  child: InkWell(
                                    onTap: () =>
                                        context.push('/rents/${tenant.id}'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Hero(
                                            tag: 'avatar-${tenant.id}',
                                            child: CircleAvatar(
                                              radius: 28,
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              child: Text(
                                                tenant.name[0].toUpperCase(),
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      tenant.name,
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (!tenant.isActive)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'INACTIVE',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone_outlined,
                                                      size: 14,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      tenant.phone,
                                                      style: TextStyle(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .colorScheme
                                                            .secondary
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${tenant.houseName ?? 'House'}: ${tenant.flatNumber ?? tenant.flatId.substring(0, 8)}',
                                                        style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .secondary,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (tenant.dueAmount > 0)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Due: ৳${tenant.dueAmount.toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .orange,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Transform.scale(
                                                scale: 0.8,
                                                child: Switch(
                                                  value: tenant.isActive,
                                                  onChanged: (isActive) {
                                                    ref
                                                        .read(
                                                          tenantProvider
                                                              .notifier,
                                                        )
                                                        .toggleTenantStatus(
                                                          tenant.id!,
                                                          isActive,
                                                        );
                                                  },
                                                  activeThumbColor:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_card_rounded,
                                                ),
                                                color:
                                                    theme.colorScheme.primary,
                                                onPressed: () => context.push(
                                                  '/add-rent/${tenant.id}',
                                                ),
                                                tooltip: 'Add Rent',
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyHouses(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Rented!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Add your first house to start managing your properties and tenants.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/houses'),
            icon: const Icon(Icons.add),
            label: const Text('Add My First House'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTenants() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showDuesOnly
                ? Icons.check_circle_outline_rounded
                : Icons.people_outline_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showDuesOnly ? 'All caught up! No dues.' : 'No tenants added yet.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
