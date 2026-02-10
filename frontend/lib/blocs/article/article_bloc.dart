import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/article_service.dart';
import 'article_event.dart';
import 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleService _articleService;

  ArticleBloc({ArticleService? articleService})
      : _articleService = articleService ?? ArticleService(),
        super(const ArticleInitial()) {
    on<ArticleLoadByCategory>(_onLoadByCategory);
    on<ArticleReset>(_onReset);
  }

  Future<void> _onLoadByCategory(
    ArticleLoadByCategory event,
    Emitter<ArticleState> emit,
  ) async {
    emit(const ArticleLoading());
    try {
      final response = await _articleService.getArticlesByCategory(event.categoryId);
      emit(ArticleListLoaded(response.data));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(ArticleError(errorMessage));
    }
  }

  void _onReset(
    ArticleReset event,
    Emitter<ArticleState> emit,
  ) {
    emit(const ArticleInitial());
  }
}

