import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'config/router.dart'; // Import the router

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await dotenv.load(); // Load environment variables

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Use the URL from .env
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Use the Anon Key from .env
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sandoog App', // Set a title for your app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/', // Set the initial route
      onGenerateRoute: AppRouter.generateRoute, // Use the router for navigation
    );
  }
}