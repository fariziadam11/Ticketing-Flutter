import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/ticket_model.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object?> get props => [];
}

class TicketLoadList extends TicketEvent {
  final String? creatorId;
  final int page;
  final int limit;

  const TicketLoadList({
    this.creatorId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [creatorId, page, limit];
}

class TicketLoadDetail extends TicketEvent {
  final String ticketId;

  const TicketLoadDetail(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class TicketCreate extends TicketEvent {
  final TicketRequest request;
  final List<PlatformFile>? attachments;

  const TicketCreate(this.request, {this.attachments});

  @override
  List<Object?> get props => [request, attachments];
}

class TicketUpdate extends TicketEvent {
  final int ticketId;
  final TicketUpdateRequest request;

  const TicketUpdate(this.ticketId, this.request);

  @override
  List<Object?> get props => [ticketId, request];
}

class TicketLoadMeta extends TicketEvent {
  const TicketLoadMeta();
}

class TicketLoadCategories extends TicketEvent {
  const TicketLoadCategories();
}

class TicketLoadComments extends TicketEvent {
  final int ticketId;

  const TicketLoadComments(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

class TicketAddComment extends TicketEvent {
  final int ticketId;
  final CommentRequest request;
  final List<PlatformFile>? attachments;

  const TicketAddComment(
    this.ticketId,
    this.request, {
    this.attachments,
  });

  @override
  List<Object?> get props => [ticketId, request, attachments];
}

class TicketReset extends TicketEvent {
  const TicketReset();
}

