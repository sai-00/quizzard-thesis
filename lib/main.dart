import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'navigation/route_observer.dart';
import 'screens/profile/profile_screen.dart';
import 'home_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/questions/question_crud_screen.dart';

// Add this import for desktop sqflite ffi
// (add dependency: sqflite_common_ffi in pubspec.yaml)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io';


void main() {
  // Only initialize ffi on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      navigatorObservers: [routeObserver], // register the observer
      // Force mobile-like MediaQuery when running on web so layouts render as on a phone.
      builder: (context, child) {
        // Typical mobile logical size to emulate (choose one that fits your target)
        const mobileSize = Size(
          390,
          844,
        ); // width x height in logical pixels (example: Pixel 6)
        if (kIsWeb) {
          final mq = MediaQuery.of(context);
          // copyWith doesn't accept orientation; orientation will be derived from size
          final data = mq.copyWith(size: mobileSize);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: mobileSize.width),
              child: MediaQuery(
                data: data,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const ProfileScreen(),
        '/menu': (context) => const MenuScreen(),
        '/questions': (context) => const QuestionCrudScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments;
          int? profileId;
          if (args is int) {
            profileId = args;
          } else if (args is Map && args['profileId'] is int) {
            profileId = args['profileId'] as int;
          } else if (args is String) {
            profileId = int.tryParse(args);
          }
          if (profileId == null) {
            // fallback to profile selection if no id provided
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          }
          // profileId is non-null here; cast to int
          return MaterialPageRoute(
            builder: (_) => HomeScreen(profileId: profileId!),
          );
        }
        return null;
      },
    );
  }
}
