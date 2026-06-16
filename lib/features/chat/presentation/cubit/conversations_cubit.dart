import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/features/chat/data/models/conversation.dart';
import 'package:houseiana_mobile_app/features/chat/presentation/cubit/conversations_state.dart';

/// Streams the signed-in user's host↔guest inbox from Firestore in realtime
/// (support threads excluded). Replaces the old direct REST call.
class ConversationsCubit extends Cubit<ConversationsState> {
  final FirestoreChatService _service;

  StreamSubscription<List<Conversation>>? _sub;

  ConversationsCubit({FirestoreChatService? service})
      : _service = service ?? sl<FirestoreChatService>(),
        super(ConversationsInitial());

  void load(String userId) {
    if (userId.isEmpty) {
      emit(const ConversationsLoaded([]));
      return;
    }
    emit(ConversationsLoading());
    _sub?.cancel();
    _sub = _service.watchConversations(userId).listen(
      (list) => emit(ConversationsLoaded(list)),
      onError: (Object e) => emit(ConversationsError(_friendly(e))),
    );
  }

  String _friendly(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'permission-denied';
    }
    return error.toString();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
