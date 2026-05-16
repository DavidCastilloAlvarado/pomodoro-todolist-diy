import 'package:birdle/data/repositories/user_repository.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/di/di_container.dart';
import 'package:birdle/ui/screens/app_shell/app_shell.dart';
import 'package:birdle/ui/screens/onboarding/onboarding_screen.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key, this.database, this.dbError});

  final BirdleDatabase? database;
  final String? dbError;

  @override
  Widget build(BuildContext context) {
    if (database == null) {
      return MaterialApp(
        title: 'Birdle',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to initialize database'),
                  const SizedBox(height: 8),
                  if (dbError != null)
                    Text(
                      dbError!,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final db = BirdleDatabase();
                      try {
                        await db.open();
                        runApp(App(database: db));
                      } catch (e) {
                        runApp(App(database: null, dbError: '$e'));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: buildProviders(database: database),
      child: Consumer<PaletteViewModel>(
        builder: (context, paletteVm, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colorScheme = isDark ? (paletteVm.darkColorScheme ?? paletteVm.colorScheme) : paletteVm.colorScheme;

          return MaterialApp(
            title: 'Birdle',
            theme: ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
            ),
            home: const AppEntryPoint(),
          );
        },
      ),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isLoading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUser();
    });
  }

  Future<void> _checkUser() async {
    final userRepo = Provider.of<UserRepository>(context, listen: false);
    final hasUser = !await userRepo.isFirstLaunch();
    if (mounted) {
      setState(() {
        _hasUser = hasUser;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasUser) {
      return const OnboardingScreen();
    }
    return const AppShell();
  }
}
