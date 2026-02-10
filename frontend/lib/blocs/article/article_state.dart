import 'package:equatable/equatable.dart';
import '../../models/article_model.dart';

abstract class ArticleState extends Equatable {
  const ArticleState();

  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {
  const ArticleInitial();
}

class ArticleLoading extends ArticleState {
  const ArticleLoading();
}

class ArticleListLoaded extends ArticleState {
  final List<Article> articles;

  const ArticleListLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}

class ArticleError extends ArticleState {
  final String message;

  const ArticleError(this.message);

  @override
  List<Object?> get props => [message];
}

