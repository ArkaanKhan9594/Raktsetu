import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'providers/app_state.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/data_repository.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_data_repository.dart';
import 'services/rest_auth_service.dart';
import 'services/rest_data_repository.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validateProductionConfig();

  AuthService authService;
  DataRepository repo;

  switch (AppConfig.backendType) {
    case BackendType.firebase:
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        authService = FirebaseAuthService();
        repo = FirestoreDataRepository();
      } catch (e) {
        authService = MockAuthService();
        repo = InMemoryDataRepository();
      }
      break;
    case BackendType.rest:
      final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
      authService = RestAuthService(apiClient: apiClient);
      repo = RestDataRepository(apiClient: apiClient);
      break;
    case BackendType.mock:
      authService = MockAuthService();
      repo = InMemoryDataRepository();
      break;
  }

  runApp(RaktSetuApp(authService: authService, repo: repo));
}

class RaktSetuApp extends StatelessWidget {
  final AuthService? authService;
  final DataRepository? repo;

  const RaktSetuApp({
    super.key,
    this.authService,
    this.repo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        auth: authService ?? MockAuthService(),
        repo: repo ?? InMemoryDataRepository(),
      ),
      child: MaterialApp(
        title: 'RaktSetu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB3122E),
            primary: const Color(0xFF1B3A6B),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1B3A6B),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            indicatorColor: Color(0xFFF4D3D9),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
