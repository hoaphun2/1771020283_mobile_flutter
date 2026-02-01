import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/screens/splash_screen.dart';
import 'package:mobile_flutter/screens/login_screen.dart';
import 'package:mobile_flutter/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_flutter/services/notification_service.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Chỉ load .env khi không phải web
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<NotificationService>(
            create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'CLB Pickleball Vọt Thủ Phổ Núi',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}