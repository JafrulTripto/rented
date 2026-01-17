import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/rent_provider.dart';
import '../../data/models/rent_payment_model.dart';
import '../../../tenant/presentation/providers/tenant_provider.dart';

class RentListPage extends ConsumerStatefulWidget {
  final String tenantId;
  const RentListPage({super.key, required this.tenantId});

  @override
  ConsumerState<RentListPage> createState() => _RentListPageState();
}

class _RentListPageState extends ConsumerState<RentListPage> {
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final rentState = ref.watch(rentListProvider(widget.tenantId));
    final tenantState = ref.watch(tenantProvider);
    final theme = Theme.of(context);

    // Find tenant
    final tenant = tenantState.tenants.isEmpty
        ? null
        : tenantState.tenants.cast<dynamic>().firstWhere(
            (t) => t.id == widget.tenantId,
            orElse: () => null,
          );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text("Rent Details"),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: "Dues", icon: Icon(Icons.warning_amber_rounded)),
              Tab(text: "History", icon: Icon(Icons.history_rounded)),
            ],
          ),
        ),
        body: rentState.when(
          data: (rents) {
            if (tenant == null)
              return const Center(child: Text("Tenant not found"));

            return TabBarView(
              children: [
                _buildDuesTab(context, tenant, rents),
                _buildHistoryTab(context, rents),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildDuesTab(
    BuildContext context,
    dynamic tenant,
    List<RentPayment> rents,
  ) {
    final theme = Theme.of(context);
    List<Widget> dueWidgets = [];

    // 1. Calculate Missing Months Dues
    // Iterate from Join Date to Current Date
    final joinDate =
        tenant.joinDate ?? DateTime.now(); // Fallback to now if null
    final now = DateTime.now();

    // Normalize dates to start of month
    var iterDate = DateTime(joinDate.year, joinDate.month);
    final targetDate = DateTime(now.year, now.month);

    final flat = tenant.flat;
    final baseRent = flat?.basicRent ?? 0.0;
    final fixedCharges =
        (flat?.gasBill ?? 0.0) +
        (flat?.utilityBill ?? 0.0) +
        (flat?.waterCharges ?? 0.0);
    // Note: Can't guess electricity for missing months, so use 0 or avg?
    // Usually "Due" implies fixed obligation. Electricity is variable.
    // Let's assume 0 electricity for missing months until entered.
    final monthlyTotalFixed = baseRent + fixedCharges;

    while (iterDate.isBefore(targetDate) ||
        iterDate.isAtSameMomentAs(targetDate)) {
      final monthStr = _months[iterDate.month - 1];
      final yearInt = iterDate.year;

      // Check if payment exists for this Month/Year
      // We might have multiple payments per month.
      final paymentsForMonth = rents
          .where((r) => r.month == monthStr && r.year == yearInt)
          .toList();

      if (paymentsForMonth.isEmpty) {
        // FULL DUE
        dueWidgets.add(
          _buildDueCard(
            month: monthStr,
            year: yearInt,
            totalDue: monthlyTotalFixed,
            status: "Not Paid",
            theme: theme,
          ),
        );
      } else {
        // PARTIAL CHECK
        // Calculate Total Paid vs Expected
        // Expected = Flat Fixed + Recorded Electricity (from first payment)
        final firstRecord = paymentsForMonth.first;
        final recordedElec = firstRecord.electricityBill;
        final totalExpected = monthlyTotalFixed + recordedElec;
        final totalPaid = paymentsForMonth.fold(
          0.0,
          (sum, r) => sum + (r.totalPaid ?? 0),
        );

        if (totalPaid < totalExpected - 1) {
          // -1 tolerance for float rounding
          dueWidgets.add(
            _buildDueCard(
              month: monthStr,
              year: yearInt,
              totalDue: totalExpected - totalPaid,
              status: "Partial Due",
              theme: theme,
              isPartial: true,
            ),
          );
        }
      }

      // Increment month
      iterDate = DateTime(iterDate.year, iterDate.month + 1);
    }

    if (dueWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Dues!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tenant is all caught up.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: dueWidgets.reversed
          .toList(), // Show recent dues first? Or chronological? List order is usually newest on top.
    );
  }

  Widget _buildDueCard({
    required String month,
    required int year,
    required double totalDue,
    required String status,
    required ThemeData theme,
    bool isPartial = false,
  }) {
    return Card(
      elevation: 0,
      color: isPartial
          ? Colors.orange.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPartial
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPartial ? Colors.orange : Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$month $year",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: isPartial ? Colors.orange[800] : Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "Due Amount",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "৳${totalDue.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<RentPayment> rents) {
    if (rents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No payment history',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: rents.length,
      itemBuilder: (context, index) {
        final rent = rents[index];
        return _buildHistoryItem(rent, theme);
      },
    );
  }

  Widget _buildHistoryItem(RentPayment rent, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: theme.colorScheme.secondary,
            ),
          ),
          title: Text(
            '${rent.month} ${rent.year}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Total: ৳${rent.totalPaid?.toStringAsFixed(2)}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Basic Rent',
                    rent.basicRent,
                    Icons.money_rounded,
                    theme,
                  ),
                  _buildDetailRow(
                    'Gas Bill',
                    rent.gasBill,
                    Icons.local_fire_department_outlined,
                    theme,
                  ),
                  _buildDetailRow(
                    'Electricity',
                    rent.electricityBill,
                    Icons.electric_bolt_outlined,
                    theme,
                  ),
                  _buildDetailRow(
                    'Utility Bill',
                    rent.utilityBill,
                    Icons.settings_outlined,
                    theme,
                  ),
                  _buildDetailRow(
                    'Water Charges',
                    rent.waterCharges,
                    Icons.water_drop_outlined,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid On',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        rent.paymentDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(rent.paymentDate!)
                            : 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    double amount,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
