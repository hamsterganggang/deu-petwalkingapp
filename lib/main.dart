import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // FlutterFire CLI로 생성됨
import 'utils/theme_data.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/walk_provider.dart';
import 'providers/social_provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/pet_service.dart';
import 'services/walk_service.dart';
import 'services/social_service.dart';
import 'services/network_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Firestore 오프라인 모드 활성화 (네트워크 없이도 캐시 사용 가능)
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // 일부 플랫폼에서는 이미 활성화되어 있을 수 있음
      debugPrint('Firestore settings error (ignored): $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Firebase가 설정되지 않은 경우에도 앱이 실행되도록 함
  }
  
  // Initialize Network Service
  try {
    await NetworkService().initialize();
  } catch (e) {
    debugPrint('Network service initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider with Firebase
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            FirebaseAuthService(),
            FirebaseUserService(),
          ),
        ),
        // Pet Provider with Firebase
        ChangeNotifierProvider(
          create: (_) => PetProvider(FirebasePetService()),
        ),
        // Walk Provider with Firebase
        ChangeNotifierProvider(
          create: (_) => WalkProvider(FirebaseWalkService()),
        ),
        // Social Provider with Firebase
        ChangeNotifierProvider(
          create: (_) => SocialProvider(FirebaseSocialService()),
        ),
      ],
      child: MaterialApp(
        title: 'Pet Walk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
