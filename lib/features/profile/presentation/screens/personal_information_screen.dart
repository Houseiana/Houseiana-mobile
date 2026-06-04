import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/gender_option.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/personal_info_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/personal_info_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();
    final userId = session.userId;

    if (userId == null || userId.isEmpty) {
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
            context.tr('profile.personalInfo'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('profile.personalInfoSignInTitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('profile.personalInfoSignInDescription'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.login,
                      arguments: {'redirectRoute': Routes.personalInformation},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                  ),
                  child: Text(context.tr('auth.signIn')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => PersonalInfoCubit()..loadProfile(userId),
      child: BlocConsumer<PersonalInfoCubit, PersonalInfoState>(
        listener: (context, state) {
          if (state is PersonalInfoSaved) {
            session.saveUser(
              userId: state.user.id,
              email: state.user.email,
              firstName: state.user.firstName,
              lastName: state.user.lastName,
              sessionId: session.sessionId,
              isHost: session.isHost,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('profile.personalInfoUpdated')),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is PersonalInfoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return _PersonalInformationContent(state: state);
        },
      ),
    );
  }
}

class _PersonalInformationContent extends StatefulWidget {
  final PersonalInfoState state;

  const _PersonalInformationContent({required this.state});

  @override
  State<_PersonalInformationContent> createState() =>
      _PersonalInformationContentState();
}

class _PersonalInformationContentState
    extends State<_PersonalInformationContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _addressController;

  bool _didHydrateFromBackend = false;
  int? _genderId;
  List<GenderOption> _genderOptions = GenderOption.fallback;
  DateTime? _selectedDate;
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    final session = sl<UserSession>();

    _firstNameController = TextEditingController(text: session.firstName ?? '');
    _lastNameController = TextEditingController(text: session.lastName ?? '');
    _emailController = TextEditingController(text: session.email ?? '');
    _originalEmail = session.email ?? '';
    _phoneController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _addressController = TextEditingController();

    _applyStateData(widget.state);
  }

  @override
  void didUpdateWidget(covariant _PersonalInformationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyStateData(widget.state);
    }
  }

  void _applyStateData(PersonalInfoState state) {
    if (state is PersonalInfoLoaded) {
      _genderOptions = state.genderOptions;
      _applyUser(state.user);
    } else if (state is PersonalInfoSaved) {
      _genderOptions = state.genderOptions;
      _applyUser(state.user);
    }
  }

  void _applyUser(UserModel user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _emailController.text = user.email ?? '';
    _originalEmail = user.email ?? '';
    _phoneController.text = user.phone ?? '';
    _addressController.text = _composeAddress(user);

    final dob = user.dateOfBirth;
    if (dob != null && dob.isNotEmpty) {
      final parsed = DateTime.tryParse(dob);
      if (parsed != null) {
        _selectedDate = parsed;
        _dateOfBirthController.text =
            '${parsed.month}/${parsed.day}/${parsed.year}';
      } else {
        _dateOfBirthController.text = dob;
      }
    } else {
      _dateOfBirthController.text = '';
    }

    _genderId = user.genderId;

    _didHydrateFromBackend = true;
  }

  String _composeAddress(UserModel user) {
    final addresses = user.addresses ?? const <AddressModel>[];
    if (addresses.isEmpty) return '';

    AddressModel address = addresses.first;
    for (final item in addresses) {
      if (item.isDefault == true) {
        address = item;
        break;
      }
    }

    final parts = [
      address.street,
      address.city,
      address.state,
      address.zipCode,
      address.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty);

    return parts.join(', ');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text =
            '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  void _retryLoad() {
    final userId = sl<UserSession>().userId;
    if (userId == null || userId.isEmpty) return;
    context.read<PersonalInfoCubit>().loadProfile(userId);
  }

  void _saveChanges() {
    final session = sl<UserSession>();
    final userId = session.userId;
    if (userId == null || userId.isEmpty) return;

    if (_formKey.currentState?.validate() != true) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final body = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      // Email changes trigger a separate verification flow on the backend, so
      // only send it when the user actually changed it (matches the web).
      if (email.isNotEmpty && email != _originalEmail) 'email': email,
      if (phone.isNotEmpty) 'phone': phone,
      // Backend expects an ISO date (`yyyy-MM-dd`), not the m/d/y display text.
      if (_selectedDate != null) 'dateOfBirth': _formatIsoDate(_selectedDate!),
      // Backend binds `genderId` (int), not a gender name string.
      if (_genderId != null) 'genderId': _genderId.toString(),
      if (address.isNotEmpty) 'address': address,
    };

    context.read<PersonalInfoCubit>().saveProfile(userId, body);
  }

  /// Formats a date as `yyyy-MM-dd` for the profile-update endpoint.
  String _formatIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Localizes the well-known gender ids while falling back to the lookup name
  /// for any others the backend may add.
  String _genderLabel(BuildContext context, GenderOption option) {
    switch (option.id) {
      case 1:
        return context.tr('profile.genderMale');
      case 2:
        return context.tr('profile.genderFemale');
      default:
        return option.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.state is PersonalInfoLoading && !_didHydrateFromBackend;
    final isSaving = widget.state is PersonalInfoSaving;
    final showTopLoader =
        widget.state is PersonalInfoLoading && _didHydrateFromBackend;
    final loadError =
        widget.state is PersonalInfoError && !_didHydrateFromBackend
            ? (widget.state as PersonalInfoError).message
            : null;

    // Only allow a pre-selected id that actually exists in the loaded options,
    // otherwise the dropdown asserts. Null renders the placeholder hint.
    final selectedGenderId =
        _genderOptions.any((o) => o.id == _genderId) ? _genderId : null;

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
          context.tr('profile.personalInfo'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? _LoadErrorState(
                  message: loadError,
                  onRetry: _retryLoad,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTopLoader) ...[
                          const LinearProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          context.tr('profile.personalInfoIntro'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(context.tr('profile.firstName')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _firstNameController,
                          hintText: context.tr('profile.enterFirstName'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('profile.firstNameValidation');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('profile.lastName')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _lastNameController,
                          hintText: context.tr('profile.enterLastName'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('profile.lastNameValidation');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('auth.emailAddress')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _emailController,
                          hintText: context.tr('auth.enterYourEmail'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('auth.validation.enterEmail');
                            }
                            if (!value.contains('@')) {
                              return context.tr('auth.validation.enterValidEmail');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('auth.phoneNumber')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _phoneController,
                          hintText: context.tr('profile.addPhoneNumber'),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            if (text.length < 7) {
                              return context.tr('profile.phoneValidation');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('profile.dateOfBirth')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _dateOfBirthController,
                          hintText: context.tr('profile.selectDateOfBirth'),
                          readOnly: true,
                          onTap: _selectDate,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('profile.gender')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedGenderId,
                              isExpanded: true,
                              hint: Text(context.tr('profile.selectGender')),
                              items: _genderOptions.map((option) {
                                return DropdownMenuItem<int>(
                                  value: option.id,
                                  child: Text(_genderLabel(context, option)),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue == null) return;
                                setState(() => _genderId = newValue);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(context.tr('profile.address')),
                        const SizedBox(height: 8),
                        _AppTextField(
                          controller: _addressController,
                          hintText: context.tr('profile.enterAddress'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.charcoal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.charcoal,
                                    ),
                                  )
                                : Text(
                                    context.tr('common.saveChanges'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffixIcon,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadErrorState({
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
