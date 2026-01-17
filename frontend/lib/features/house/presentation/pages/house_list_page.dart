import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/house/presentation/providers/house_provider.dart';

class HouseListPage extends ConsumerWidget {
  const HouseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseState = ref.watch(houseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: houseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : houseState.error != null
          ? Center(child: Text('Error: ${houseState.error}'))
          : houseState.houses.isEmpty
          ? _buildEmptyHouses()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: houseState.houses.length,
              itemBuilder: (context, index) {
                final house = houseState.houses[index];
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
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        house.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${house.flats.length} Units Available',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      children: [
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ...house.flats.map(
                          (flat) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.door_back_door_outlined,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            title: Text(
                              'Flat ${flat.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showAddFlatDialog(context, ref, house.id),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add New Flat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.secondary,
                              side: BorderSide(
                                color: theme.colorScheme.secondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHouseDialog(context, ref),
        label: const Text(
          'New House',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_business_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyHouses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No houses added yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showAddHouseDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add House'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'House Name',
            hintText: 'e.g. Green Villa',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(houseProvider.notifier)
                    .addHouse(controller.text);
                if (context.mounted) context.pop();
              }
            },
            child: const Text('Add House'),
          ),
        ],
      ),
    );
  }

  void _showAddFlatDialog(BuildContext context, WidgetRef ref, String houseId) {
    final numberController = TextEditingController();
    final basicRentController = TextEditingController();
    final gasBillController = TextEditingController();
    final utilityBillController = TextEditingController();
    final waterChargesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Flat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Flat Number',
                  hintText: 'e.g. A1, 202',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: basicRentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Basic Rent',
                  hintText: '0.0',
                  prefixText: '৳',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gasBillController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gas Bill',
                  hintText: '0.0',
                  prefixText: '৳',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: utilityBillController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Utility Bill',
                  hintText: '0.0',
                  prefixText: '৳',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waterChargesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Water Charges',
                  hintText: '0.0',
                  prefixText: '৳',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                await ref
                    .read(houseProvider.notifier)
                    .addFlat(
                      houseId,
                      numberController.text,
                      double.tryParse(basicRentController.text) ?? 0.0,
                      double.tryParse(gasBillController.text) ?? 0.0,
                      double.tryParse(utilityBillController.text) ?? 0.0,
                      double.tryParse(waterChargesController.text) ?? 0.0,
                    );
                if (context.mounted) context.pop();
              }
            },
            child: const Text('Add Flat'),
          ),
        ],
      ),
    );
  }
}
