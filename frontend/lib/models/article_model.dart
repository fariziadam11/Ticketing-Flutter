class ArticleAttachment {
  final int id;
  final String url;
  final String name;

  ArticleAttachment({
    required this.id,
    required this.url,
    required this.name,
  });

  factory ArticleAttachment.fromJson(Map<String, dynamic> json) {
    return ArticleAttachment(
      id: Article.parseInt(json['id']) ?? 0,
      url: Article.parseString(json['url']) ?? '',
      name: Article.parseString(json['name']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
    };
  }
}

class Article {
  final int? id;
  final String? title;
  final String? content;
  final String? summary;
  final int? categoryId;
  final String? categoryName;
  final int? authorId;
  final int? responsibleId;
  final int? creationDate;
  final int? lastUpdateDate;
  final int? createdAt;
  final int? updatedAt;
  final String? status;
  final int? views;
  final int? helpful;
  final String? solvedRequests;
  final double? rating;
  final bool? isPrivate;
  final List<ArticleAttachment>? attachments;
  final List<dynamic>? tags;
  final Map<String, dynamic>? metadata;

  Article({
    this.id,
    this.title,
    this.content,
    this.summary,
    this.categoryId,
    this.categoryName,
    this.authorId,
    this.responsibleId,
    this.creationDate,
    this.lastUpdateDate,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.views,
    this.helpful,
    this.solvedRequests,
    this.rating,
    this.isPrivate,
    this.attachments,
    this.tags,
    this.metadata,
  });

  // Helper untuk parse int yang bisa dari berbagai tipe
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Helper untuk parse string
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  // Helper untuk parse double
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    // Parse attachments
    List<ArticleAttachment>? attachments;
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachments = (json['attachments'] as List<dynamic>)
            .map((item) => ArticleAttachment.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return Article(
      id: parseInt(json['id']),
      title: parseString(json['title'] ?? json['name']),
      content: parseString(json['content'] ?? json['body'] ?? json['description']),
      summary: parseString(json['summary'] ?? json['excerpt']),
      categoryId: parseInt(json['category_id'] ?? json['categoryId']),
      categoryName: parseString(json['category_name'] ?? json['categoryName']),
      authorId: parseInt(json['author_id'] ?? json['authorId']),
      responsibleId: parseInt(json['responsible_id'] ?? json['responsibleId']),
      creationDate: parseInt(json['creation_date'] ?? json['creationDate'] ?? json['created_at'] ?? json['createdAt'] ?? json['date_created']),
      lastUpdateDate: parseInt(json['last_update_date'] ?? json['lastUpdateDate'] ?? json['updated_at'] ?? json['updatedAt'] ?? json['date_updated']),
      createdAt: parseInt(json['created_at'] ?? json['createdAt'] ?? json['date_created'] ?? json['creation_date']),
      updatedAt: parseInt(json['updated_at'] ?? json['updatedAt'] ?? json['date_updated'] ?? json['last_update_date']),
      status: parseString(json['status'] ?? json['state']),
      views: parseInt(json['views'] ?? json['view_count']),
      helpful: parseInt(json['helpful'] ?? json['helpful_count']),
      solvedRequests: parseString(json['solved_requests'] ?? json['solvedRequests']),
      rating: parseDouble(json['rating']),
      isPrivate: json['is_private'] as bool? ?? json['isPrivate'] as bool?,
      attachments: attachments,
      tags: json['tags'] as List<dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category_id': categoryId,
      'category_name': categoryName,
      'author_id': authorId,
      'responsible_id': responsibleId,
      'creation_date': creationDate,
      'last_update_date': lastUpdateDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status': status,
      'views': views,
      'helpful': helpful,
      'solved_requests': solvedRequests,
      'rating': rating,
      'is_private': isPrivate,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'tags': tags,
      'metadata': metadata,
    };
  }
}

class ArticleListResponse {
  final List<Article> data;

  ArticleListResponse({required this.data});

  factory ArticleListResponse.fromJson(Map<String, dynamic> json) {
    // Handle berbagai format response
    List<dynamic>? dataList;
    
    if (json['data'] != null) {
      if (json['data'] is List) {
        dataList = json['data'] as List<dynamic>;
      } else if (json['data'] is Map) {
        // Jika data adalah object, coba ambil array di dalamnya
        final dataMap = json['data'] as Map<String, dynamic>;
        if (dataMap['data'] is List) {
          dataList = dataMap['data'] as List<dynamic>;
        } else if (dataMap['articles'] is List) {
          dataList = dataMap['articles'] as List<dynamic>;
        }
      }
    } else if (json['articles'] is List) {
      dataList = json['articles'] as List<dynamic>;
    }
    
    final data = dataList ?? [];
    
    // Parse articles dengan error handling yang lebih baik
    final articles = <Article>[];
    for (final item in data) {
      try {
        if (item is Map<String, dynamic>) {
          final article = Article.fromJson(item);
          // Hanya tambahkan jika article valid (punya id)
          if (article.id != null) {
            articles.add(article);
          }
        }
      } catch (e) {
        // Log error tapi skip item yang invalid
        // print('Error parsing article: $e');
        continue;
      }
    }
    
    return ArticleListResponse(data: articles);
  }
}

