import 'package:equatable/equatable.dart';
import '../../models/ticket_model.dart';

abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {
  const TicketInitial();
}

class TicketLoading extends TicketState {
  const TicketLoading();
}

class TicketListLoaded extends TicketState {
  final TicketListResponse response;

  const TicketListLoaded(this.response);

  @override
  List<Object?> get props => [response];
}

class TicketDetailLoaded extends TicketState {
  final Ticket ticket;

  const TicketDetailLoaded(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class TicketCreated extends TicketState {
  final Ticket ticket;

  const TicketCreated(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class TicketUpdated extends TicketState {
  final Ticket ticket;

  const TicketUpdated(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class TicketMetaLoaded extends TicketState {
  final TicketMeta meta;
  final List<Category> categories;

  const TicketMetaLoaded({
    required this.meta,
    required this.categories,
  });

  @override
  List<Object?> get props => [meta, categories];
}

class TicketCommentsLoaded extends TicketState {
  final List<Comment> comments;

  const TicketCommentsLoaded(this.comments);

  @override
  List<Object?> get props => [comments];
}

class TicketCommentAdded extends TicketState {
  final Comment comment;

  const TicketCommentAdded(this.comment);

  @override
  List<Object?> get props => [comment];
}

class TicketError extends TicketState {
  final String message;

  const TicketError(this.message);

  @override
  List<Object?> get props => [message];
}

