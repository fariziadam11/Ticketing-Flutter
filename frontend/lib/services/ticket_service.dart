import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../models/ticket_model.dart';
import '../utils/api_client.dart';
import '../utils/attachments_utils.dart';

class TicketService {
  /// Create ticket tanpa attachment (JSON body).
  Future<Ticket> createTicket(TicketRequest request) async {
    final response = await ApiClient.post(
      '/tickets',
      body: request.toJson(),
    );

    if (response.statusCode == 201) {
      return Ticket.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to create ticket');
    }
  }

  /// Create ticket dengan attachment (multipart/form-data),
  /// mengikuti perilaku frontend-website.
  Future<Ticket> createTicketWithAttachments(
    TicketRequest request,
    List<PlatformFile> files,
  ) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/tickets');
    final multipartRequest = http.MultipartRequest('POST', uri);

    // Headers dengan Authorization
    // Content-Type akan di-set otomatis oleh MultipartRequest
    final headers = await ApiClient.getAuthHeaders();
    headers.remove('Content-Type');
    multipartRequest.headers.addAll(headers);

    // Fields – sesuai dengan web frontend
    multipartRequest.fields['source_id'] = request.sourceId.toString();
    multipartRequest.fields['category_id'] = request.categoryId.toString();
    multipartRequest.fields['type_id'] = request.typeId.toString();
    multipartRequest.fields['priority_id'] = request.priorityId.toString();
    multipartRequest.fields['title'] = request.title;
    multipartRequest.fields['description'] = request.description;

    final timestamp = request.dateOcurred ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    multipartRequest.fields['date_ocurred'] = timestamp.toString();

    // Attachments
    final multipartFiles = await buildAttachmentMultipartFiles(files);
    multipartRequest.files.addAll(multipartFiles);

    final streamed = await multipartRequest.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return Ticket.fromJson(
        ApiClient.parseRawJson(response.body),
      );
    } else {
      final error = ApiClient.parseRawJson(response.body);
      throw Exception(error['error'] ?? 'Failed to create ticket');
    }
  }

  Future<TicketListResponse> getTickets({
    String? creatorId,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (creatorId != null && creatorId.isNotEmpty) {
      queryParams['creator_id'] = creatorId;
    }

    final response = await ApiClient.get(
      '/tickets',
      queryParams: queryParams,
    );

    if (response.statusCode == 200) {
      return TicketListResponse.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch tickets');
    }
  }

  Future<Ticket> getTicketById(String id) async {
    final response = await ApiClient.get('/tickets/$id');

    if (response.statusCode == 200) {
      return Ticket.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch ticket');
    }
  }

  Future<Ticket> updateTicket(int id, TicketUpdateRequest request) async {
    final response = await ApiClient.put(
      '/tickets/$id',
      body: request.toJson(),
    );

    if (response.statusCode == 200) {
      return Ticket.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to update ticket');
    }
  }

  Future<CommentListResponse> getComments(int ticketId) async {
    final response = await ApiClient.get('/tickets/$ticketId/comments');

    if (response.statusCode == 200) {
      return CommentListResponse.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch comments');
    }
  }

  Future<Comment> addComment(int ticketId, CommentRequest request) async {
    final response = await ApiClient.post(
      '/tickets/$ticketId/comments',
      body: request.toJson(),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to add comment');
    }
  }

  /// Add comment dengan attachments (multipart/form-data),
  /// mengikuti perilaku frontend-website.
  Future<Comment> addCommentWithAttachments(
    int ticketId,
    String message,
    List<PlatformFile> files,
  ) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/tickets/$ticketId/comments');
    final multipartRequest = http.MultipartRequest('POST', uri);

    final headers = await ApiClient.getAuthHeaders();
    headers.remove('Content-Type');
    multipartRequest.headers.addAll(headers);

    multipartRequest.fields['comment'] = message;

    final multipartFiles = await buildAttachmentMultipartFiles(files);
    multipartRequest.files.addAll(multipartFiles);

    final streamed = await multipartRequest.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return Comment.fromJson(
        ApiClient.parseRawJson(response.body),
      );
    } else {
      final error = ApiClient.parseRawJson(response.body);
      throw Exception(error['error'] ?? 'Failed to add comment');
    }
  }

  Future<Uint8List> getAttachment(String attachmentId) async {
    final response = await ApiClient.get(
      '/tickets/attachments/$attachmentId',
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to download attachment');
    }
  }

  Future<Map<String, dynamic>> getInvGateUser(int userId) async {
    final response = await ApiClient.get('/users/$userId');

    if (response.statusCode == 200) {
      return ApiClient.parseResponse(response);
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch user');
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await ApiClient.get('/categories', includeAuth: false);

    if (response.statusCode == 200) {
      final json = ApiClient.parseResponse(response);
      // Backend mengembalikan {"data": [...]}
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch categories');
    }
  }

  Future<List<Status>> getStatuses() async {
    final response = await ApiClient.get('/statuses', includeAuth: false);

    if (response.statusCode == 200) {
      final data = ApiClient.parseListResponse(response);
      return data
          .map((item) => Status.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch statuses');
    }
  }

  Future<TicketMeta> getTicketMeta() async {
    final response = await ApiClient.get('/ticket-meta', includeAuth: false);

    if (response.statusCode == 200) {
      return TicketMeta.fromJson(ApiClient.parseResponse(response));
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch ticket meta');
    }
  }

  Future<void> acceptSolution(int ticketId, SolutionRequest request) async {
    final response = await ApiClient.put(
      '/tickets/$ticketId/solution',
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to accept solution');
    }
  }

  Future<void> rejectSolution(int ticketId, SolutionRejectRequest request) async {
    final response = await ApiClient.put(
      '/tickets/$ticketId/solution/reject',
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to reject solution');
    }
  }

  Future<List<int>> getArticlesByCategory(int categoryId) async {
    final response = await ApiClient.get(
      '/articles',
      queryParams: {'category_id': categoryId.toString()},
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final data = ApiClient.parseListResponse(response);
      return data.cast<int>();
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch articles');
    }
  }
}

