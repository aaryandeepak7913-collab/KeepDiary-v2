import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const KeepApp());
}

class KeepApp extends StatelessWidget {
  const KeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF14172B),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE8A33D),
          secondary: const Color(0xFFE8A33D),
          surface: const Color(0xFF1E2340),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Holds the vault's decryption key only in memory — never written to disk.
/// Locking the app (or backgrounding it, eventually) just drops this and
/// falls back to the lock screen, exactly like the web version.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  SecretKey? _vaultKey;

  void _unlock(SecretKey key) => setState(() => _vaultKey = key);
  void _lock() => setState(() => _vaultKey = null);

  @override
  Widget build(BuildContext context) {
    if (_vaultKey == null) {
      return LockScreen(onUnlocked: _unlock);
    }
    return HomeScreen(vaultKey: _vaultKey!, onLock: _lock);
  }
}
