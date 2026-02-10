import '../models/article_model.dart';
import '../utils/api_client.dart';

class ArticleService {
  /// Get articles by category ID
  /// GET /api/v1/articles?category_id={categoryId}
  Future<ArticleListResponse> getArticlesByCategory(int categoryId) async {
    try {
      final response = await ApiClient.get( 
        '/articles',
        queryParams: {'category_id': categoryId.toString()},
        includeAuth: false, // Articles are public
      );

      if (response.statusCode == 200) {
        final json = ApiClient.parseResponse(response);
        return ArticleListResponse.fromJson(json);
      } else {
        final error = ApiClient.parseResponse(response);
        final errorMessage =
            error['error'] ?? error['message'] ?? 'Failed to fetch articles';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw dengan message yang lebih jelas
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch articles: ${e.toString()}');
    }
  }
}
