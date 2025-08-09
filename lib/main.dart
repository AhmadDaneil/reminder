import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reminder/screens/add_notes.dart';
import 'package:reminder/screens/add_reminder.dart';
import 'package:reminder/screens/notes.dart';
import 'package:reminder/screens/loading.dart';
import 'package:reminder/screens/home.dart';
import 'package:reminder/screens/settings.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/noti_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await NotificationService.init();
  runApp(
    ChangeNotifierProvider(
    create: (_) => SettingsProvider(),
    child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _){
        return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: settings.isDarkmode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: settings.backgroundColor,
        textTheme: _getTextTheme(settings.fontSize).apply(bodyColor: settings.fontColor,
        displayColor: settings.fontColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: settings.appBarColor,
          iconTheme: IconThemeData(color: settings.fontColor),
          titleTextStyle: TextStyle(
            color: settings.fontColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: settings.fontColor),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: settings.fontColor),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: settings.fontColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: settings.fontColor),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Loading(),
        '/home': (context) => const Home(),
        '/notes': (context) => const Notes(),
        '/add_notes': (context) => AddNotes(),
        '/add_reminder': (context) => const AddReminder(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
    );
      }
    
  TextTheme _getTextTheme(String size) {
    double fontSize;
        switch (size) {
          case 'Small':
            fontSize= 12.0;
            break;
          case 'Large':
            fontSize = 20.0;
            break;
          case 'Medium':
            fontSize = 16.0;
            break;
          default:
            fontSize = 14.0;
        }
    return TextTheme(
    bodySmall: TextStyle(fontSize: fontSize),
    bodyMedium: TextStyle(fontSize: fontSize),
    bodyLarge: TextStyle(fontSize: fontSize),
    titleSmall: TextStyle(fontSize: fontSize),
    titleMedium: TextStyle(fontSize: fontSize),
    titleLarge: TextStyle(fontSize: fontSize),
    labelSmall: TextStyle(fontSize: fontSize),
    labelMedium: TextStyle(fontSize: fontSize),
    labelLarge: TextStyle(fontSize: fontSize),
    headlineSmall: TextStyle(fontSize: fontSize),
    headlineMedium: TextStyle(fontSize: fontSize),
    headlineLarge: TextStyle(fontSize: fontSize),
  );
  }
}