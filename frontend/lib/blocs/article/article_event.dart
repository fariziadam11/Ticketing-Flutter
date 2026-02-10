import 'package:equatable/equatable.dart';

abstract class ArticleEvent extends Equatable {
  const ArticleEvent();

  @override
  List<Object?> get props => [];
}

class ArticleLoadByCategory extends ArticleEvent {
  final int categoryId;

  const ArticleLoadByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ArticleReset extends ArticleEvent {
  const ArticleReset();
}

