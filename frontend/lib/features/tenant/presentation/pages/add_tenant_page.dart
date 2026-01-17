import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/tenant/presentation/providers/tenant_provider.dart';
import 'package:frontend/features/house/presentation/providers/house_provider.dart';

class AddTenantPage extends ConsumerStatefulWidget {
  const AddTenantPage({super.key});

  @override
  ConsumerState<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends ConsumerState<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nidNumberController = TextEditingController();
  final _advanceAmountController = TextEditingController();

  String? _selectedHouseId;
  String? _selectedFlatId;
  DateTime _joinDate = DateTime.now();
  List<File> _nidImages = [];

  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        if (pickedFiles.length != 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select exactly 2 images')),
            );
          }
          return;
        }
        setState(() {
          _nidImages = pickedFiles.map((f) => File(f.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open gallery: $e')));
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHouseId == null || _selectedFlatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a house and flat')),
        );
        return;
      }

      if (_nidImages.length != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload exactly 2 NID images')),
        );
        return;
      }

      try {
        await ref
            .read(tenantProvider.notifier)
            .addTenant(
              name: _nameController.text,
              phone: _phoneController.text,
              houseId: _selectedHouseId!,
              flatId: _selectedFlatId!,
              nidNumber: _nidNumberController.text,
              advanceAmount:
                  double.tryParse(_advanceAmountController.text) ?? 0,
              joinDate: _joinDate,
              nidFront: _nidImages[0],
              nidBack: _nidImages[1],
            );
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding tenant: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final houseState = ref.watch(houseProvider);
    final theme = Theme.of(context);

    final selectedHouse = _selectedHouseId != null
        ? houseState.houses.firstWhere((h) => h.id == _selectedHouseId)
        : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                theme,
                'Personal Information',
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(
                theme,
                'Property Details',
                Icons.home_work_outlined,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedHouseId,
                decoration: const InputDecoration(
                  labelText: 'Select House',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: houseState.houses.map((h) {
                  return DropdownMenuItem(value: h.id, child: Text(h.name));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedHouseId = v;
                    _selectedFlatId = null;
                  });
                },
                validator: (v) => v == null ? 'Select a house' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedFlatId,
                decoration: const InputDecoration(
                  labelText: 'Select Flat',
                  prefixIcon: Icon(Icons.door_back_door_outlined),
                ),
                items:
                    selectedHouse?.flats.map((f) {
                      return DropdownMenuItem(
                        value: f.id,
                        child: Text('Flat ${f.number}'),
                      );
                    }).toList() ??
                    [],
                onChanged: (v) => setState(() => _selectedFlatId = v),
                validator: (v) => v == null ? 'Select a flat' : null,
                disabledHint: const Text('Select a house first'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _advanceAmountController,
                decoration: const InputDecoration(
                  labelText: 'Advance Payment',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter advance amount' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Joining Date'),
                subtitle: Text(
                  '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joinDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _joinDate = picked);
                },
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(
                theme,
                'Identity Verification',
                Icons.fingerprint_outlined,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nidNumberController,
                decoration: const InputDecoration(
                  labelText: 'NID Number',
                  prefixIcon: Icon(Icons.perm_identity_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Enter NID number' : null,
              ),
              const SizedBox(height: 20),
              _buildUnifiedImagePicker(theme),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'REGISTER TENANT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedImagePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NID PHOTOS (FRONT & BACK)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        if (_nidImages.isEmpty)
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select 2 Photos',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Front and back images required',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildImagePreview(_nidImages[0], 'Front')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildImagePreview(_nidImages[1], 'Back')),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Change Photos'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImagePreview(File image, String label) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
