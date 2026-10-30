import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/app_state.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    debugPrint(
      'Firebase initialization skipped on web: Firebase web options are not configured.',
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
    }
  }

  Object? initializationError;
  try {
    await AppState.initialize();
  } catch (error) {
    initializationError = error;
  }
  runApp(BloodBankApp(initializationError: initializationError));
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key, this.initializationError});

  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Bank Locator',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFFB42332),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFFB42332),
              onPrimary: Colors.white,
              secondary: const Color(0xFF486581),
              primaryContainer: const Color(0xFFFFE8EA),
              onPrimaryContainer: const Color(0xFF7A1D29),
              surfaceContainerLow: const Color(0xFFFFFBFB),
              surface: Colors.white,
              error: const Color(0xFFB42332),
            ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: Color(0xFF334E68), height: 1.4),
          bodyMedium: TextStyle(color: Color(0xFF52606D), height: 1.4),
          bodySmall: TextStyle(color: Color(0xFF7B8794), height: 1.3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB42332),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFEFE),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintStyle: TextStyle(color: Color(0xFF829AB1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD9E2EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD9E2EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFB42332), width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF52606D)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB42332),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            elevation: 0,
            overlayColor: const Color(0x22FFFFFF),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB42332),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            side: const BorderSide(color: Color(0xFFB42332)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB42332),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE3E8EF)),
          ),
          shadowColor: Color(0x140F2742),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          iconColor: Color(0xFFB42332),
          titleTextStyle: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.w700,
          ),
          subtitleTextStyle: TextStyle(color: Color(0xFF52606D)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFE8EA),
          elevation: 2,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF172B4D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFFB42332),
        ),
      ),

      home: initializationError == null
          ? const Splash()
          : _DatabaseStartupFailure(error: initializationError!),
    );
  }
}

class _DatabaseStartupFailure extends StatefulWidget {
  const _DatabaseStartupFailure({required this.error});

  final Object error;

  @override
  State<_DatabaseStartupFailure> createState() =>
      _DatabaseStartupFailureState();
}

class _DatabaseStartupFailureState extends State<_DatabaseStartupFailure> {
  Object? retryError;
  bool retrying = false;

  Future<void> retryInitialization() async {
    setState(() => retrying = true);
    try {
      await AppState.initialize();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Splash()));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        retryError = error;
        retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = retryError ?? widget.error;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to start Blood Bank Locator',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The local database could not be initialized. The app has not opened its sign-in or dashboard screens.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Details: $error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: retrying ? null : retryInitialization,
                    icon: retrying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(retrying ? 'Retrying...' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
