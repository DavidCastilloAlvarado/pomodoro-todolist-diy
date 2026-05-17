import 'package:birdle/ui/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/di/di_container.dart';
import 'package:birdle/ui/screens/item_detail_page.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
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
          final colorScheme = isDark
              ? (paletteVm.darkColorScheme ?? paletteVm.colorScheme)
              : paletteVm.colorScheme;

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
            home: const SplashScreen(),
            routes: {
              '/item_detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final listId = args is String ? args : '';
                return ItemDetailPage(listId: listId);
              },
            },
          );
        },
      ),
    );
  }
}
