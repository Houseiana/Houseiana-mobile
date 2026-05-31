import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PropertySetupScreen extends StatefulWidget {
  const PropertySetupScreen({super.key});

  @override
  State<PropertySetupScreen> createState() => _PropertySetupScreenState();
}

class _PropertySetupScreenState extends State<PropertySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  Map<String, dynamic> _prevArgs = {};
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _prevArgs = args;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
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
          context.tr('host.propertySetupTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(context.tr('host.propertyTitleLabel')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _decor(context.tr('host.propertyTitleHint')),
                validator: (v) => (v == null || v.isEmpty) ? context.tr('host.propertyTitleValidation') : null,
              ),

              const SizedBox(height: 24),
              _label(context.tr('host.descriptionLabel')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _decor(context.tr('host.descriptionHint')),
                validator: (v) => (v == null || v.isEmpty) ? context.tr('host.descriptionValidation') : null,
              ),

              const SizedBox(height: 24),
              _label(context.tr('host.cityLabel')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                decoration: _decor(context.tr('host.cityHint')),
                validator: (v) => (v == null || v.isEmpty) ? context.tr('host.cityValidation') : null,
              ),

              const SizedBox(height: 24),
              _label(context.tr('host.addressLabel')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: _decor(context.tr('host.addressHint')),
                validator: (v) => (v == null || v.isEmpty) ? context.tr('host.addressValidation') : null,
              ),

              const SizedBox(height: 24),
              _label(context.tr('host.photosLabel')),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate, size: 40, color: AppColors.neutral400),
                      const SizedBox(height: 8),
                      Text(context.tr('host.addPhotosOptional'), style: const TextStyle(color: AppColors.neutral600)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushNamed(
                        context,
                        Routes.pricingSetup,
                        arguments: {
                          ..._prevArgs,
                          'title': _titleController.text.trim(),
                          'description': _descriptionController.text.trim(),
                          'city': _cityController.text.trim(),
                          'address': _addressController.text.trim(),
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    context.tr('host.continueToPricing'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      );

  InputDecoration _decor(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      );
}
