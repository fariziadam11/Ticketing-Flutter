class Ticket {
  final int? id;
  final String? prettyId;
  final String title;
  final String description;
  final int sourceId;
  final int creatorId;
  final int customerId;
  final int categoryId;
  final int typeId;
  final int priorityId;
  final int? statusId;
  final String? status;
  final int? createdAt;
  final int? lastUpdate;
  final int? dateOcurred;
  final int? closedAt;
  final String? closedReason;
  final int? solvedAt;
  final int? rating;
  final int? assignedId;
  final int? assignedGroupId;
  final int? locationId;
  final int? processId;
  final List<dynamic>? attachments;
  final List<dynamic>? customFields;

  Ticket({
    this.id,
    this.prettyId,
    required this.title,
    required this.description,
    required this.sourceId,
    required this.creatorId,
    required this.customerId,
    required this.categoryId,
    required this.typeId,
    required this.priorityId,
    this.statusId,
    this.status,
    this.createdAt,
    this.lastUpdate,
    this.dateOcurred,
    this.closedAt,
    this.closedReason,
    this.solvedAt,
    this.rating,
    this.assignedId,
    this.assignedGroupId,
    this.locationId,
    this.processId,
    this.attachments,
    this.customFields,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Handle id yang bisa int, int64, float64, atau string
    int? parseId(dynamic id) {
      if (id == null) return null;
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      if (id is double) return id.toInt();
      return null;
    }
    
    // Helper untuk parse int field
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    return Ticket(
      id: parseId(json['id']),
      prettyId: json['pretty_id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sourceId: parseInt(json['source_id'], 0),
      creatorId: parseInt(json['creator_id'], 0),
      customerId: parseInt(json['customer_id'], 0),
      categoryId: parseInt(json['category_id'], 0),
      typeId: parseInt(json['type_id'], 0),
      priorityId: parseInt(json['priority_id'], 0),
      statusId: parseId(json['status_id']),
      status: json['status']?.toString(),
      createdAt: parseId(json['created_at']),
      lastUpdate: parseId(json['last_update']),
      dateOcurred: parseId(json['date_ocurred']),
      closedAt: parseId(json['closed_at']),
      closedReason: json['closed_reason']?.toString(),
      solvedAt: parseId(json['solved_at']),
      rating: parseId(json['rating']),
      assignedId: parseId(json['assigned_id']),
      assignedGroupId: parseId(json['assigned_group_id']),
      locationId: parseId(json['location_id']),
      processId: parseId(json['process_id']),
      attachments: json['attachments'] as List<dynamic>?,
      customFields: json['custom_fields'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'creator_id': creatorId,
      'customer_id': customerId,
      'category_id': categoryId,
      'type_id': typeId,
      'priority_id': priorityId,
      'title': title,
      'description': description,
      if (dateOcurred != null) 'date_ocurred': dateOcurred,
    };
  }
}

class TicketRequest {
  final int sourceId;
  final int creatorId;
  final int customerId;
  final int categoryId;
  final int typeId;
  final int priorityId;
  final String title;
  final String description;
  final int? dateOcurred;

  TicketRequest({
    required this.sourceId,
    required this.creatorId,
    required this.customerId,
    required this.categoryId,
    required this.typeId,
    required this.priorityId,
    required this.title,
    required this.description,
    this.dateOcurred,
  });

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'creator_id': creatorId,
      'customer_id': customerId,
      'category_id': categoryId,
      'type_id': typeId,
      'priority_id': priorityId,
      'title': title,
      'description': description,
      if (dateOcurred != null) 'date_ocurred': dateOcurred,
    };
  }
}

class TicketUpdateRequest {
  final int? sourceId;
  final int? creatorId;
  final int? customerId;
  final int? categoryId;
  final int? typeId;
  final int? priorityId;
  final String? title;
  final String? description;
  final int? dateOcurred;

  TicketUpdateRequest({
    this.sourceId,
    this.creatorId,
    this.customerId,
    this.categoryId,
    this.typeId,
    this.priorityId,
    this.title,
    this.description,
    this.dateOcurred,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (sourceId != null) json['source_id'] = sourceId;
    if (creatorId != null) json['creator_id'] = creatorId;
    if (customerId != null) json['customer_id'] = customerId;
    if (categoryId != null) json['category_id'] = categoryId;
    if (typeId != null) json['type_id'] = typeId;
    if (priorityId != null) json['priority_id'] = priorityId;
    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (dateOcurred != null) json['date_ocurred'] = dateOcurred;
    return json;
  }
}

class TicketListResponse {
  final String? pageKey;
  final List<Ticket> data;

  TicketListResponse({
    this.pageKey,
    required this.data,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    // Handle data yang bisa List atau langsung array
    List<dynamic>? dataList;
    if (json['data'] != null) {
      if (json['data'] is List) {
        dataList = json['data'] as List<dynamic>;
      } else {
        dataList = [json['data']];
      }
    }
    
    return TicketListResponse(
      pageKey: json['page_key']?.toString(),
      data: dataList
              ?.map((item) {
                try {
                  if (item is Map<String, dynamic>) {
                    return Ticket.fromJson(item);
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .whereType<Ticket>()
              .toList() ??
          [],
    );
  }
}

class Comment {
  final int? id;
  final int? incidentId;
  final int? authorId;
  final String? message;
  final String? comment; // legacy field
  final String? author;
  final int? createdAt;
  final bool? customerVisible;
  final bool? isSolution;
  final int? msgNum;
  final List<dynamic>? attachedFiles;
  final List<dynamic>? attachments;
  final dynamic reference;

  Comment({
    this.id,
    this.incidentId,
    this.authorId,
    this.message,
    this.comment,
    this.author,
    this.createdAt,
    this.customerVisible,
    this.isSolution,
    this.msgNum,
    this.attachedFiles,
    this.attachments,
    this.reference,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Helper untuk parse int
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }
    
    // Helper untuk parse bool
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return null;
    }
    
    return Comment(
      id: parseId(json['id']),
      incidentId: parseId(json['incident_id']),
      authorId: parseId(json['author_id']),
      message: json['message']?.toString() ?? json['comment']?.toString(),
      comment: json['comment']?.toString(),
      author: json['author']?.toString(),
      createdAt: parseId(json['created_at']),
      customerVisible: parseBool(json['customer_visible']),
      isSolution: parseBool(json['is_solution']),
      msgNum: parseId(json['msg_num']),
      attachedFiles: json['attached_files'] as List<dynamic>?,
      attachments: json['attachments'] as List<dynamic>?,
      reference: json['reference']?.toString(),
    );
  }
}

class CommentRequest {
  final String comment;
  // Note: request_id is taken from URL, author_id is taken from JWT token by backend

  CommentRequest({
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
    };
  }
}

class CommentListResponse {
  final List<Comment> data;

  CommentListResponse({required this.data});

  factory CommentListResponse.fromJson(Map<String, dynamic> json) {
    return CommentListResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Comment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Attachment {
  final int id;
  final String name;
  final String? url;
  final String? hash;
  final String? extension;

  Attachment({
    required this.id,
    required this.name,
    this.url,
    this.hash,
    this.extension,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    // Helper untuk parse int
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }
    
    return Attachment(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString(),
      hash: json['hash']?.toString(),
      extension: json['extension']?.toString(),
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle id yang bisa int atau string
    int parseId(dynamic id) {
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
      return 0;
    }

    return Category(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class Status {
  final int id;
  final String name;
  final String? description;

  Status({
    required this.id,
    required this.name,
    this.description,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    // Handle id yang bisa int atau string
    int parseId(dynamic id) {
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
      return 0;
    }

    return Status(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class TicketMeta {
  final List<Category> categories;
  final List<Status> statuses;
  final List<dynamic> types;
  final List<dynamic> priorities;
  final List<dynamic> sources;

  TicketMeta({
    required this.categories,
    required this.statuses,
    required this.types,
    required this.priorities,
    required this.sources,
  });

  factory TicketMeta.fromJson(Map<String, dynamic> json) {
    return TicketMeta(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((item) => Status.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      types: (json['types'] as List<dynamic>?) ?? [],
      priorities: (json['priorities'] as List<dynamic>?) ?? [],
      sources: (json['sources'] as List<dynamic>?) ?? [],
    );
  }
}

class SolutionRequest {
  final int requestId;
  final int rating;
  final String comment;

  SolutionRequest({
    required this.requestId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class SolutionRejectRequest {
  final int requestId;
  final String comment;

  SolutionRejectRequest({
    required this.requestId,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'comment': comment,
    };
  }
}

