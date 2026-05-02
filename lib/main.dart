import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'bloc/news_bloc.dart';
import 'data/datasources/gemini_data_source.dart';
import 'data/datasources/news_remote_data_source.dart';
import 'data/repositories/news_repository.dart';
import 'presentation/screens/news_screen.dart';

void main() async {
  await dotenv.load();
  
  // Load API keys for all categories
  final apiKeys = {
    'Tech': dotenv.env['GEMINI_API_KEY_TECH'] ?? '',
    'Sports': dotenv.env['GEMINI_API_KEY_SPORTS'] ?? '',
    'Politics': dotenv.env['GEMINI_API_KEY_POLITICS'] ?? '',
    'Crypto': dotenv.env['GEMINI_API_KEY_CRYPTO'] ?? '',
    'Design': dotenv.env['GEMINI_API_KEY_DESIGN'] ?? '',
  };
  
  // Verify that at least one API key is available
  if (apiKeys.values.every((key) => key.isEmpty)) {
    throw Exception('No API keys found in .env file');
  }
  
  final remoteDataSource = NewsRemoteDataSource(apiKeys: apiKeys);
  final repository = NewsRepository(remoteDataSource: remoteDataSource);

  runApp(NewsApp(repository: repository));
}

class NewsApp extends StatelessWidget {
  final NewsRepository repository;

  const NewsApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsBloc(repository: repository),
      child: MaterialApp(
        title: 'Tech News',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.lime,
            accentColor: Colors.red,
            backgroundColor: Colors.red,
            cardColor: Colors.grey.shade900.withAlpha(128),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey.shade800),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
          chipTheme: ChipThemeData(
            labelStyle: TextStyle(color: Colors.white)
          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 21),
        ),
        home: const NewsScreen(),
      ),
    );
  }
}
