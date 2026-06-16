import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/identity_verification_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/identity_verification_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Identity Verification — the mobile parity of the web personal-info identity
/// sections. Lets the user add/update their Government ID (passport / national
/// id) and an emergency contact against the real backend endpoints.
class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();
    if (!session.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar(context),
        body: _LoginRequired(),
      );
    }

    return BlocProvider(
      create: (_) => sl<IdentityVerificationCubit>()..load(),
      child: const _IdentityView(),
    );
  }
}

AppBar _appBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      context.tr('profile.identityVerification'),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
    ),
    centerTitle: true,
  );
}

class _IdentityView extends StatelessWidget {
  const _IdentityView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: BlocConsumer<IdentityVerificationCubit, IdentityVerificationState>(
        listenWhen: (prev, curr) =>
            prev.messageId != curr.messageId && curr.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(state.message!)),
              backgroundColor:
                  state.messageIsError ? AppColors.error : AppColors.success,
            ),
          );
        },
        builder: (context, state) {
          switch (state.status) {
            case IdentityLoadStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case IdentityLoadStatus.error:
              return _LoadError(
                message: context.tr(state.loadError ?? 'common.error'),
                onRetry: () => context.read<IdentityVerificationCubit>().load(),
              );
            case IdentityLoadStatus.ready:
              return _IdentityForm(state: state);
          }
        },
      ),
    );
  }
}

class _IdentityForm extends StatelessWidget {
  final IdentityVerificationState state;

  const _IdentityForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IdentityVerificationCubit>();
    // Key the alert off actual displayable content, not mere map presence — an
    // empty record from the backend can still come back as a non-null wrapper.
    final hasGovId = _maskedSummary(state.passport, 'passportNumber') != null ||
        _maskedSummary(state.nationalId, 'idNumber') != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('profile.identityIntro'),
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
          ),
          const SizedBox(height: 20),
          if (!hasGovId) ...[
            _CompletionAlert(),
            const SizedBox(height: 20),
          ],
          _GroupLabel(context.tr('profile.governmentId')),
          const SizedBox(height: 12),
          _PassportSection(
            data: state.passport,
            isSaving: state.savingSection == 'passport',
            onSave: cubit.savePassport,
          ),
          _NationalIdSection(
            data: state.nationalId,
            isSaving: state.savingSection == 'nationalId',
            onSave: cubit.saveNationalId,
          ),
          const SizedBox(height: 12),
          _GroupLabel(context.tr('profile.emergencyContact')),
          const SizedBox(height: 12),
          _EmergencyContactSection(
            data: state.emergencyContact,
            relationshipOptions: state.relationshipOptions,
            isSaving: state.savingSection == 'emergencyContact',
            onSave: cubit.saveEmergencyContact,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Passport ────────────────────────────────────────────────────────────────

class _PassportSection extends StatefulWidget {
  final Map<String, dynamic>? data;
  final bool isSaving;
  final void Function(Map<String, dynamic> body) onSave;

  const _PassportSection({
    required this.data,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_PassportSection> createState() => _PassportSectionState();
}

class _PassportSectionState extends State<_PassportSection> {
  bool _expanded = false;
  final _number = TextEditingController();
  late final TextEditingController _country;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _country = TextEditingController(
        text: widget.data?['issuingCountry']?.toString() ?? '');
    _issueDate = _parseDate(widget.data?['issueDate']);
    _expiryDate = _parseDate(widget.data?['expiryDate']);
  }

  @override
  void dispose() {
    _number.dispose();
    _country.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PassportSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The cubit only swaps this section's `data` instance when *this* record was
    // re-fetched after a save, so re-seed from the server-canonical values then.
    if (!identical(oldWidget.data, widget.data)) {
      _number.clear();
      _country.text = widget.data?['issuingCountry']?.toString() ?? '';
      _issueDate = _parseDate(widget.data?['issueDate']);
      _expiryDate = _parseDate(widget.data?['expiryDate']);
    }
  }

  void _save() {
    final number = _number.text.trim();
    final country = _country.text.trim();
    widget.onSave({
      'passportNumber': number,
      if (country.isNotEmpty) 'issuingCountry': country,
      if (_issueDate != null) 'issueDate': _isoDate(_issueDate!),
      if (_expiryDate != null) 'expiryDate': _isoDate(_expiryDate!),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: context.tr('profile.passport'),
      summary: _maskedSummary(widget.data, 'passportNumber'),
      emptyHint: context.tr('profile.addPassportDetails'),
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: context.tr('profile.passportNumber'),
            controller: _number,
            hint: context.tr('profile.passportNumber'),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: context.tr('profile.issuingCountry'),
            controller: _country,
            hint: context.tr('profile.enterIssuingCountry'),
          ),
          const SizedBox(height: 14),
          _DateRow(
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            onIssue: (d) {
              if (!mounted) return;
              setState(() => _issueDate = d);
            },
            onExpiry: (d) {
              if (!mounted) return;
              setState(() => _expiryDate = d);
            },
          ),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: _number,
            builder: (context, _) => _SaveButton(
              isSaving: widget.isSaving,
              enabled: _number.text.trim().isNotEmpty,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

// ── National ID ───────────────────────────────────────────────────────────────

class _NationalIdSection extends StatefulWidget {
  final Map<String, dynamic>? data;
  final bool isSaving;
  final void Function({
    required Map<String, dynamic> fields,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) onSave;

  const _NationalIdSection({
    required this.data,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_NationalIdSection> createState() => _NationalIdSectionState();
}

class _NationalIdSectionState extends State<_NationalIdSection> {
  bool _expanded = false;
  final _number = TextEditingController();
  late final TextEditingController _country;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  String? _frontPath;
  String? _backPath;

  @override
  void initState() {
    super.initState();
    _country = TextEditingController(
        text: widget.data?['issuingCountry']?.toString() ?? '');
    _issueDate = _parseDate(widget.data?['issueDate']);
    _expiryDate = _parseDate(widget.data?['expiryDate']);
  }

  @override
  void dispose() {
    _number.dispose();
    _country.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NationalIdSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _number.clear();
      _country.text = widget.data?['issuingCountry']?.toString() ?? '';
      _issueDate = _parseDate(widget.data?['issueDate']);
      _expiryDate = _parseDate(widget.data?['expiryDate']);
      // A fresh server record arrived — drop the local picks so the box shows
      // the newly uploaded frontImageUrl/backImageUrl instead of the stale file.
      _frontPath = null;
      _backPath = null;
    }
  }

  void _save() {
    final number = _number.text.trim();
    final country = _country.text.trim();
    widget.onSave(
      fields: {
        'idNumber': number,
        if (country.isNotEmpty) 'issuingCountry': country,
        if (_issueDate != null) 'issueDate': _isoDate(_issueDate!),
        if (_expiryDate != null) 'expiryDate': _isoDate(_expiryDate!),
      },
      frontPhotoPath: _frontPath,
      backPhotoPath: _backPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.badge_outlined,
      title: context.tr('profile.nationalId'),
      summary: _maskedSummary(widget.data, 'idNumber'),
      emptyHint: context.tr('profile.addNationalIdDetails'),
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: context.tr('profile.idNumber'),
            controller: _number,
            hint: context.tr('profile.idNumber'),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: context.tr('profile.issuingCountry'),
            controller: _country,
            hint: context.tr('profile.enterIssuingCountry'),
          ),
          const SizedBox(height: 14),
          _DateRow(
            issueDate: _issueDate,
            expiryDate: _expiryDate,
            onIssue: (d) {
              if (!mounted) return;
              setState(() => _issueDate = d);
            },
            onExpiry: (d) {
              if (!mounted) return;
              setState(() => _expiryDate = d);
            },
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _UploadBox(
                  label: context.tr('profile.uploadFrontSide'),
                  localPath: _frontPath,
                  existingUrl: widget.data?['frontImageUrl']?.toString(),
                  onTap: () async {
                    final path = await _pickImage(context);
                    if (!mounted) return;
                    if (path != null) setState(() => _frontPath = path);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UploadBox(
                  label: context.tr('profile.uploadBackSide'),
                  localPath: _backPath,
                  existingUrl: widget.data?['backImageUrl']?.toString(),
                  onTap: () async {
                    final path = await _pickImage(context);
                    if (!mounted) return;
                    if (path != null) setState(() => _backPath = path);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: _number,
            builder: (context, _) => _SaveButton(
              isSaving: widget.isSaving,
              enabled: _number.text.trim().isNotEmpty,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emergency Contact ─────────────────────────────────────────────────────────

class _EmergencyContactSection extends StatefulWidget {
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>> relationshipOptions;
  final bool isSaving;
  final void Function(Map<String, dynamic> body) onSave;

  const _EmergencyContactSection({
    required this.data,
    required this.relationshipOptions,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_EmergencyContactSection> createState() =>
      _EmergencyContactSectionState();
}

class _EmergencyContactSectionState extends State<_EmergencyContactSection> {
  bool _expanded = false;
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  String? _relationshipId; // id.toString()

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _fullName = TextEditingController(text: d?['fullName']?.toString() ?? '');
    _phone = TextEditingController(text: d?['phoneNumber']?.toString() ?? '');
    _whatsapp =
        TextEditingController(text: d?['whatsappNumber']?.toString() ?? '');
    _email = TextEditingController(
        text: (d?['emailAddress'] ?? d?['email'])?.toString() ?? '');
    _relationshipId = d?['relationship']?.toString();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EmergencyContactSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      final d = widget.data;
      _fullName.text = d?['fullName']?.toString() ?? '';
      _phone.text = d?['phoneNumber']?.toString() ?? '';
      _whatsapp.text = d?['whatsappNumber']?.toString() ?? '';
      _email.text = (d?['emailAddress'] ?? d?['email'])?.toString() ?? '';
      _relationshipId = d?['relationship']?.toString();
    }
  }

  void _save() {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final whatsapp = _whatsapp.text.trim();
    final email = _email.text.trim();

    // Recover the raw lookup id (int) from the selected string value so we send
    // the stable id the backend expects, not the localized name.
    Object? rawId;
    for (final opt in widget.relationshipOptions) {
      if (opt['id'].toString() == _relationshipId) {
        rawId = opt['id'];
        break;
      }
    }

    widget.onSave({
      'fullName': fullName,
      if (rawId != null) 'relationship': rawId,
      if (phone.isNotEmpty) 'phoneNumber': phone,
      if (whatsapp.isNotEmpty) 'whatsappNumber': whatsapp,
      if (email.isNotEmpty) 'emailAddress': email,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.contact_phone_outlined,
      title: context.tr('profile.emergencyContact'),
      summary: _emergencySummary(widget.data, widget.relationshipOptions),
      emptyHint: context.tr('profile.addEmergencyContact'),
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            label: context.tr('profile.contactName'),
            controller: _fullName,
            hint: context.tr('profile.contactName'),
          ),
          const SizedBox(height: 14),
          _FieldLabel(context.tr('profile.relationship')),
          const SizedBox(height: 8),
          _Dropdown(
            value: widget.relationshipOptions
                    .any((o) => o['id'].toString() == _relationshipId)
                ? _relationshipId
                : null,
            hint: context.tr('profile.selectRelationship'),
            items: widget.relationshipOptions
                .map((o) => DropdownMenuItem<String>(
                      value: o['id'].toString(),
                      child: Text(o['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _relationshipId = v),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: context.tr('auth.phoneNumber'),
            controller: _phone,
            hint: context.tr('auth.phoneNumber'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: context.tr('profile.whatsappNumber'),
            controller: _whatsapp,
            hint: context.tr('profile.whatsappNumber'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: context.tr('profile.emailOptional'),
            controller: _email,
            hint: context.tr('auth.emailAddress'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: _fullName,
            builder: (context, _) => _SaveButton(
              isSaving: widget.isSaving,
              enabled: _fullName.text.trim().isNotEmpty,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared building blocks ────────────────────────────────────────────────────

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Builds a "•••• 1234 · Country" summary line, preferring the backend masked
/// number, falling back to the raw number. Returns null when no number exists.
String? _maskedSummary(Map<String, dynamic>? data, String numberKey) {
  if (data == null) return null;
  final number = (data['numberMasked'] ??
          data[numberKey] ??
          data['number'])
      ?.toString();
  if (number == null || number.isEmpty) return null;
  final country = data['issuingCountry']?.toString();
  return (country != null && country.isNotEmpty) ? '$number · $country' : number;
}

String? _emergencySummary(
    Map<String, dynamic>? data, List<Map<String, dynamic>> options) {
  if (data == null) return null;
  final name = data['fullName']?.toString();
  if (name == null || name.isEmpty) return null;
  final relId = data['relationship']?.toString();
  String? relName;
  for (final o in options) {
    if (o['id'].toString() == relId) {
      relName = o['name']?.toString();
      break;
    }
  }
  return (relName != null && relName.isNotEmpty) ? '$name ($relName)' : name;
}

Future<String?> _pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(ctx.tr('profile.takePhoto')),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(ctx.tr('profile.chooseFromGallery')),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked =
      await ImagePicker().pickImage(source: source, imageQuality: 80);
  return picked?.path;
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? summary;
  final String emptyHint;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.emptyHint,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = summary != null && summary!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasValue ? summary! : emptyHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasValue
                                ? AppColors.charcoal
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final ValueChanged<DateTime> onIssue;
  final ValueChanged<DateTime> onExpiry;

  const _DateRow({
    required this.issueDate,
    required this.expiryDate,
    required this.onIssue,
    required this.onExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: context.tr('profile.issueDate'),
            value: issueDate,
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            onPicked: onIssue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: context.tr('profile.expiryDate'),
            value: expiryDate,
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            onPicked: onExpiry,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryColor,
            onPrimary: AppColors.charcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? _isoDate(value!)
                        : context.tr('profile.selectDate'),
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? AppColors.charcoal
                          : AppColors.neutral500,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 18, color: AppColors.neutral600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final String? localPath;
  final String? existingUrl;
  final VoidCallback onTap;

  const _UploadBox({
    required this.label,
    required this.localPath,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null;
    final hasExisting = !hasLocal && (existingUrl?.isNotEmpty ?? false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
          image: hasLocal
              ? DecorationImage(
                  image: FileImage(io.File(localPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasLocal
            ? null
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasExisting
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      size: 26,
                      color: hasExisting
                          ? AppColors.success
                          : AppColors.neutral400,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        hasExisting
                            ? context.tr('profile.tapToReplace')
                            : label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
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

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final bool enabled;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (isSaving || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.charcoal,
          disabledBackgroundColor: AppColors.neutral400.withValues(alpha: 0.4),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _CompletionAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFB923C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('profile.completeProfile'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('profile.completeProfileDesc'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEA580C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

class _LoginRequired extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 52, color: AppColors.neutral500),
            const SizedBox(height: 16),
            Text(
              context.tr('profile.signInForKyc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('profile.signInForKycDescription'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.login,
                  arguments: {'redirectRoute': Routes.kycVerification},
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(context.tr('auth.signIn')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
