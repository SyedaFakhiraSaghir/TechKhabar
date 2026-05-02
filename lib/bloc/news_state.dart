import '../data/models/news_item.dart';

abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoadingMore extends NewsState {
  final List<NewsItem> news;
  NewsLoadingMore(this.news);
}

class NewsLoaded extends NewsState {
  final List<NewsItem> news;
  final String category;
  final bool hasMore;

  NewsLoaded(this.news, {this.category = 'Tech', this.hasMore = true});
}

class NewsError extends NewsState {
  final String message;

  NewsError(this.message);
}


