import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/support_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';

abstract class SupportState {
  const SupportState();
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportTicketCreated extends SupportState {
  final Map<String, dynamic> ticket;
  const SupportTicketCreated(this.ticket);
}

class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);
}

class SupportCubit extends Cubit<SupportState> {
  final SupportService _supportService;
  final UserSession _session;

  SupportCubit(this._supportService, this._session)
      : super(SupportInitial());

  Future<void> submitTicket({
    required String subject,
    required String message,
    required String category,
    String? contactName,
    String? contactEmail,
    String? priority,
  }) async {
    final userId = _session.userId;
    final email = contactEmail ?? _session.email;

    emit(SupportLoading());
    try {
      final ticket = await _supportService.createTicket(
        userId: userId,
        subject: subject,
        message: message,
        category: category,
        contactName: contactName,
        contactEmail: email,
        priority: priority,
      );
      emit(SupportTicketCreated(ticket));
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  void reset() => emit(SupportInitial());
}
