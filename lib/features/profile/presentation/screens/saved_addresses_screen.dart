import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/saved_addresses_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/saved_addresses_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SavedAddressesCubit>().loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('profile.savedAddresses'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SavedAddressesCubit, SavedAddressesState>(
        listener: (context, state) {
          if (state is SavedAddressesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is SavedAddressesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SavedAddressesError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context.read<SavedAddressesCubit>().loadAddresses(),
            );
          }

          final addresses = _addressesFromState(state);
          final isAdding = state is SavedAddressAdding;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<SavedAddressesCubit>().loadAddresses(),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const _AddressNotice(),
                      const SizedBox(height: 24),
                      if (addresses.isEmpty)
                        const _EmptyAddresses()
                      else
                        ...addresses.map(
                          (address) => _AddressCard(
                            address: address,
                            isBusy: _isBusyAddress(state, address.id),
                            onSetDefault: () => _setDefault(address),
                            onEdit: () => _showAddressDialog(address: address),
                            onDelete: () => _deleteAddress(address),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isAdding ? null : () => _showAddressDialog(),
                    icon: isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(context.tr('profile.addNewAddress')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AddressModel> _addressesFromState(SavedAddressesState state) {
    if (state is SavedAddressesLoaded) return state.addresses;
    if (state is SavedAddressAdding) return state.addresses;
    if (state is SavedAddressDeleting) return state.addresses;
    if (state is SavedAddressUpdating) return state.addresses;
    return const [];
  }

  bool _isBusyAddress(SavedAddressesState state, String addressId) {
    return (state is SavedAddressDeleting && state.addressId == addressId) ||
        (state is SavedAddressUpdating && state.addressId == addressId);
  }

  void _showAddressDialog({AddressModel? address}) {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: address?.label ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final countryController =
        TextEditingController(text: address?.country ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          address == null
              ? context.tr('profile.addNewAddress')
              : context.tr('profile.editAddress'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.addressLabel'),
                    hintText: context.tr('profile.addressLabelHint'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? context.tr('profile.addressLabelValidation')
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: streetController,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.street'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? context.tr('profile.streetValidation')
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cityController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.city'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: countryController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.country'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final city = cityController.text.trim();
              final country = countryController.text.trim();
              if (address == null) {
                context.read<SavedAddressesCubit>().addAddress(
                      label: labelController.text.trim(),
                      street: streetController.text.trim(),
                      city: city.isEmpty ? null : city,
                      country: country.isEmpty ? null : country,
                    );
              } else {
                context.read<SavedAddressesCubit>().updateAddress(
                      addressId: address.id,
                      label: labelController.text.trim(),
                      street: streetController.text.trim(),
                      city: city.isEmpty ? null : city,
                      state: address.state,
                      zipCode: address.zipCode,
                      country: country.isEmpty ? null : country,
                      isDefault: address.isDefault,
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: Text(
              address == null
                  ? context.tr('profile.add')
                  : context.tr('profile.save'),
            ),
          ),
        ],
      ),
    );
  }

  void _setDefault(AddressModel address) {
    context.read<SavedAddressesCubit>().updateAddress(
          addressId: address.id,
          label: address.label ?? 'Address',
          street: address.street ?? '',
          city: address.city,
          state: address.state,
          zipCode: address.zipCode,
          country: address.country,
          isDefault: true,
        );
  }

  void _deleteAddress(AddressModel address) {
    final label = address.label ?? 'Address';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.deleteAddressTitle'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.tr('profile.deleteAddressConfirm', args: {'label': label}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SavedAddressesCubit>().deleteAddress(address.id);
            },
            child: Text(
              context.tr('profile.deleteAction'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressNotice extends StatelessWidget {
  const _AddressNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.charcoal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('profile.savedAddressesNotice'),
              style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isBusy;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isBusy,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final line = [address.street, address.city, address.country]
        .where((item) => item != null && item.trim().isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: address.isDefault == true
              ? AppColors.primaryColor
              : const Color(0xFFE5E7EB),
          width: address.isDefault == true ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: AppColors.charcoal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.label ?? 'Address',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    if (address.isDefault == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.tr('profile.defaultBadge'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.neutral600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                if (address.isDefault != true)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(context.tr('profile.setAsDefault')),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr('profile.editAction')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(context.tr('profile.deleteAction'), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'default') {
                  onSetDefault();
                } else if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off, size: 42, color: AppColors.neutral500),
          const SizedBox(height: 12),
          Text(
            context.tr('profile.noSavedAddresses'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('profile.noSavedAddressesDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
