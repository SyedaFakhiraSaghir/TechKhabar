import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../data/repositories/news_repository.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository repository;

  NewsBloc({required this.repository}) : super(NewsInitial()) {
    on<LoadNews>(_onLoadNews);
  }

  Future<void> _onLoadNews(
    LoadNews event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    try {
      developer.log('Loading news...');
      final news = await repository.getTechNews();
      developer.log('Loaded ${news.length} news items');
      emit(NewsLoaded(news));
    } catch (e) {
      developer.log('Error loading news: $e');
      emit(NewsError(e.toString()));
    }
  }
}


