import 'package:equatable/equatable.dart';

enum IdentityLoadStatus { loading, ready, error }

/// Single immutable state for the Identity Verification screen.
///
/// It holds the loaded passport / national-id / emergency-contact records plus
/// the relationship lookup options, tracks which section is currently saving,
/// and carries a one-shot feedback message for the snackbar. [messageId]
/// increments on every feedback emission so the UI can tell two identical
/// messages apart (and avoid re-showing on plain rebuilds).
class IdentityVerificationState extends Equatable {
  final IdentityLoadStatus status;
  final String? loadError;

  final Map<String, dynamic>? passport;
  final Map<String, dynamic>? nationalId;
  final Map<String, dynamic>? emergencyContact;
  final List<Map<String, dynamic>> relationshipOptions;

  /// 'passport' | 'nationalId' | 'emergencyContact' while saving, else null.
  final String? savingSection;

  final String? message;
  final bool messageIsError;
  final int messageId;

  const IdentityVerificationState({
    this.status = IdentityLoadStatus.loading,
    this.loadError,
    this.passport,
    this.nationalId,
    this.emergencyContact,
    this.relationshipOptions = const [],
    this.savingSection,
    this.message,
    this.messageIsError = false,
    this.messageId = 0,
  });

  static const Object _noChange = Object();

  IdentityVerificationState copyWith({
    IdentityLoadStatus? status,
    String? loadError,
    Object? passport = _noChange,
    Object? nationalId = _noChange,
    Object? emergencyContact = _noChange,
    List<Map<String, dynamic>>? relationshipOptions,
    Object? savingSection = _noChange,
    String? message,
    bool? messageIsError,
    int? messageId,
  }) {
    return IdentityVerificationState(
      status: status ?? this.status,
      loadError: loadError ?? this.loadError,
      passport: passport == _noChange
          ? this.passport
          : passport as Map<String, dynamic>?,
      nationalId: nationalId == _noChange
          ? this.nationalId
          : nationalId as Map<String, dynamic>?,
      emergencyContact: emergencyContact == _noChange
          ? this.emergencyContact
          : emergencyContact as Map<String, dynamic>?,
      relationshipOptions: relationshipOptions ?? this.relationshipOptions,
      savingSection: savingSection == _noChange
          ? this.savingSection
          : savingSection as String?,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        loadError,
        passport,
        nationalId,
        emergencyContact,
        relationshipOptions,
        savingSection,
        message,
        messageIsError,
        messageId,
      ];
}
