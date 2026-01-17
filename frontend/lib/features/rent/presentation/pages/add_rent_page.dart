import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/rent_provider.dart';
import '../../data/models/rent_payment_model.dart';
import '../../../tenant/presentation/providers/tenant_provider.dart';

class AddRentPage extends ConsumerStatefulWidget {
  final String tenantId;
  const AddRentPage({super.key, required this.tenantId});

  @override
  ConsumerState<AddRentPage> createState() => _AddRentPageState();
}

class _AddRentPageState extends ConsumerState<AddRentPage> {
  final _formKey = GlobalKey<FormState>();

  final _basicRentController = TextEditingController();
  final _electricityBillController = TextEditingController();

  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedYear = DateTime.now().year;

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

  /// Returns (totalExpected, totalPaid, due, existingElectricity)
  /// If no record exists, returns (0, 0, 0, null)
  (double, double, double, double?) _calculateExistingStatus(
    List<RentPayment> rents,
    double flatTotalExpected,
  ) {
    print(
      'Calculating status for $_selectedMonth $_selectedYear with ${rents.length} records',
    );
    final monthRents = rents
        .where((r) => r.month == _selectedMonth && r.year == _selectedYear)
        .toList();

    if (monthRents.isEmpty) return (0, 0, 0, null);

    // Assuming the first record defines the "Variable" bill structure (Electricity)
    // If multiple records represent installments, the total expected bill remains constant based on the first record?
    // Or do we sum up bills?
    // User request implies "Full rent due" vs "Partial".
    // Let's assume the TOTAL EXPECTED for the month = Flat Defaults + (First Record's Electricity OR Current Input?)
    // If electricity was 0 in first payment (maybe forgotten?), this might be tricky.
    // But usually first payment sets the standard.

    // Let's take the MAX electricity found (in case of correction) or just the first one.
    // Simpler: Use the first record's electricity as the "billed" amount.
    final firstRecord = monthRents.first;
    final recordedElectricity = firstRecord.electricityBill;

    final totalExpected = flatTotalExpected + recordedElectricity;
    final totalPaid = monthRents.fold(
      0.0,
      (sum, item) => sum + (item.totalPaid ?? 0),
    );
    final due = totalExpected - totalPaid;

    return (totalExpected, totalPaid, due, recordedElectricity);
  }

  double _calculateTotal(
    double gas,
    double utility,
    double water,
    double dueAmount,
    bool isDueMode,
  ) {
    if (isDueMode) return dueAmount;

    double total = 0;
    total += double.tryParse(_basicRentController.text) ?? 0;
    total += double.tryParse(_electricityBillController.text) ?? 0;
    total += gas;
    total += utility;
    total += water;
    return total;
  }

  void _submit(
    double gas,
    double utility,
    double water,
    double dueAmount,
    bool isDueMode,
  ) async {
    // If isDueMode, we are paying the remaining balance.
    // We attribute it to BasicRent for simplicity in data structure, or we'd need a "Due" field.
    // Since backend sums up fields to TotalPaid, we just put it in BasicRent and zero others.

    final basicRent = isDueMode
        ? dueAmount
        : (double.tryParse(_basicRentController.text) ?? 0);
    final electricity = isDueMode
        ? 0.0
        : (double.tryParse(_electricityBillController.text) ?? 0);
    final gasVal = isDueMode ? 0.0 : gas;
    final utilityVal = isDueMode ? 0.0 : utility;
    final waterVal = isDueMode ? 0.0 : water;

    // Validate only if not due mode (input fields matter)
    if (isDueMode || _formKey.currentState!.validate()) {
      final rent = RentPayment(
        tenantId: widget.tenantId,
        month: _selectedMonth,
        year: _selectedYear,
        basicRent: basicRent,
        electricityBill: electricity,
        gasBill: gasVal,
        utilityBill: utilityVal,
        waterCharges: waterVal,
      );

      try {
        await ref
            .read(rentListProvider(widget.tenantId).notifier)
            .addRent(rent);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding rent: $e')));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Removed monthlyRent initialization
    _basicRentController.addListener(() => setState(() {}));
    _electricityBillController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _basicRentController.dispose();
    _electricityBillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenantState = ref.watch(tenantProvider);
    final rentListState = ref.watch(rentListProvider(widget.tenantId));

    // Find tenant
    final tenant = tenantState.tenants.isEmpty
        ? null
        : tenantState.tenants.cast<dynamic>().firstWhere(
            (t) => t.id == widget.tenantId,
            orElse: () => null,
          );

    if (tenant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Add Rent")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final flat = tenant.flat;
    final gas = flat?.gasBill ?? 0.0;
    final utility = flat?.utilityBill ?? 0.0;
    final water = flat?.waterCharges ?? 0.0;
    final basicRentRef =
        flat?.basicRent ?? 0.0; // Use detailed flat rent if available, else 0

    // Determine Status
    // Link tenant rent to flat basic rent
    final effectiveBasicRent = basicRentRef;
    final flatExpectedWithoutElec = effectiveBasicRent + gas + utility + water;

    final (
      totalExpected,
      totalPaid,
      due,
      recordedElec,
    ) = _calculateExistingStatus(
      rentListState.value ?? [],
      flatExpectedWithoutElec,
    );

    final bool recordExists =
        totalPaid > 0 || (totalExpected > 0 && recordedElec != null);
    final bool isFullyPaid = recordExists && due <= 0;
    final bool isPartial = recordExists && due > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text("Add Rent")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                theme,
                'Payment Period',
                Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        prefixIcon: Icon(Icons.event_note_outlined),
                      ),
                      items: _months
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _selectedYear.toString(),
                      decoration: const InputDecoration(labelText: 'Year'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _selectedYear = int.tryParse(v) ?? _selectedYear,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (isFullyPaid)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Rent for $_selectedMonth $_selectedYear is fully paid!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isPartial)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          const Text(
                            "Partial Payment Detected",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Total Bill: ৳${totalExpected.toStringAsFixed(2)}"),
                      Text("Paid So Far: ৳${totalPaid.toStringAsFixed(2)}"),
                      const Divider(),
                      Text(
                        "Remaining Due: ৳${due.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              if (!isFullyPaid && !isPartial) ...[
                _buildSectionHeader(
                  theme,
                  'Variable Amounts',
                  Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 16),
                _buildField(
                  _basicRentController,
                  'Basic Rent',
                  Icons.money_rounded,
                  theme,
                ),
                const SizedBox(height: 16),
                _buildField(
                  _electricityBillController,
                  'Electricity Bill',
                  Icons.electric_bolt_outlined,
                  theme,
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(
                  theme,
                  'Fixed Charges (Included)',
                  Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                _buildFixedChargeRow('Gas Bill', gas, theme),
                _buildFixedChargeRow('Utility Bill', utility, theme),
                _buildFixedChargeRow('Water Charges', water, theme),
              ],

              const SizedBox(height: 32),

              if (!isFullyPaid)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPartial ? 'PAYING DUE' : 'TOTAL PAYMENT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '৳${_calculateTotal(gas, utility, water, due, isPartial).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () =>
                            _submit(gas, utility, water, due, isPartial),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isPartial ? 'PAY REMAINING DUE' : 'SUBMIT PAYMENT',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
    ThemeData theme,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: '৳',
      ),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Enter amount' : null,
    );
  }

  Widget _buildFixedChargeRow(String label, double amount, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
