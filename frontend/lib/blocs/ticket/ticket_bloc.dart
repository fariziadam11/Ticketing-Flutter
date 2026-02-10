import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketService _ticketService;

  TicketBloc({
    TicketService? ticketService,
  })  : _ticketService = ticketService ?? TicketService(),
        super(const TicketInitial()) {
    on<TicketLoadList>(_onLoadList);
    on<TicketLoadDetail>(_onLoadDetail);
    on<TicketCreate>(_onCreate);
    on<TicketUpdate>(_onUpdate);
    on<TicketLoadMeta>(_onLoadMeta);
    on<TicketLoadCategories>(_onLoadCategories);
    on<TicketLoadComments>(_onLoadComments);
    on<TicketAddComment>(_onAddComment);
    on<TicketReset>(_onReset);
  }

  Future<void> _onLoadList(
    TicketLoadList event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final response = await _ticketService.getTickets(
        creatorId: event.creatorId,
        page: event.page,
        limit: event.limit,
      );
      emit(TicketListLoaded(response));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
    TicketLoadDetail event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final ticket = await _ticketService.getTicketById(event.ticketId);
      emit(TicketDetailLoaded(ticket));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onCreate(
    TicketCreate event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final ticket = event.attachments != null && event.attachments!.isNotEmpty
          ? await _ticketService.createTicketWithAttachments(
              event.request,
              event.attachments!,
            )
          : await _ticketService.createTicket(event.request);
      emit(TicketCreated(ticket));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    TicketUpdate event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final ticket = await _ticketService.updateTicket(
        event.ticketId,
        event.request,
      );
      emit(TicketUpdated(ticket));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onLoadMeta(
    TicketLoadMeta event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final results = await Future.wait([
        _ticketService.getTicketMeta(),
        _ticketService.getCategories(),
      ]);
      final meta = results[0] as TicketMeta;
      final categories = results[1] as List<Category>;
      emit(TicketMetaLoaded(meta: meta, categories: categories));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    TicketLoadCategories event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final categories = await _ticketService.getCategories();
      // For categories only, we still need meta for other data
      final meta = await _ticketService.getTicketMeta();
      emit(TicketMetaLoaded(meta: meta, categories: categories));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onLoadComments(
    TicketLoadComments event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final response = await _ticketService.getComments(event.ticketId);
      emit(TicketCommentsLoaded(response.data));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onAddComment(
    TicketAddComment event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final comment = event.attachments != null && event.attachments!.isNotEmpty
          ? await _ticketService.addCommentWithAttachments(
              event.ticketId,
              event.request.comment,
              event.attachments!,
            )
          : await _ticketService.addComment(event.ticketId, event.request);
      emit(TicketCommentAdded(comment));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  void _onReset(
    TicketReset event,
    Emitter<TicketState> emit,
  ) {
    emit(const TicketInitial());
  }
}

