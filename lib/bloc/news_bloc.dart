import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../data/repositories/news_repository.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository repository;
  List<dynamic> _allNews = [];
  String _currentCategory = 'Tech';

  NewsBloc({required this.repository}) : super(NewsInitial()) {
    on<LoadNews>(_onLoadNews);
    on<LoadMoreNews>(_onLoadMoreNews);
  }

  Future<void> _onLoadNews(
    LoadNews event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    try {
      _currentCategory = event.category;
      developer.log('Loading news for category: ${event.category}');
      
      late final newsList;
      if (event.category == 'Tech') {
        newsList = await repository.getTechNews();
      } else {
        newsList = await repository.getNewsByTopic(event.category);
      }
      
      _allNews = newsList;
      developer.log('Loaded ${newsList.length} news items for ${event.category}');
      emit(NewsLoaded(newsList, category: event.category, hasMore: true));
    } catch (e) {
      developer.log('Error loading news: $e');
      emit(NewsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreNews(
    LoadMoreNews event,
    Emitter<NewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is NewsLoaded) {
      emit(NewsLoadingMore(currentState.news));
      try {
        _currentCategory = event.category;
        developer.log('Loading more news for category: ${event.category}');
        
        late final newsList;
        if (event.category == 'Tech') {
          newsList = await repository.getTechNews();
        } else {
          newsList = await repository.getNewsByTopic(event.category);
        }
        
        final updatedNews = [...currentState.news, ...newsList];
        _allNews = updatedNews;
        developer.log('Loaded more news. Total: ${updatedNews.length}');
        emit(NewsLoaded(updatedNews, category: event.category, hasMore: true));
      } catch (e) {
        developer.log('Error loading more news: $e');
        emit(NewsError(e.toString()));
      }
    }
  }
}


