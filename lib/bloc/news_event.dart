abstract class NewsEvent {}

class LoadNews extends NewsEvent {
  final String category;
  LoadNews({this.category = 'Tech'});
}

class LoadMoreNews extends NewsEvent {
  final String category;
  LoadMoreNews({this.category = 'Tech'});
}


