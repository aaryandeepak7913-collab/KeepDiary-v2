import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';

class LockScreen extends StatefulWidget {
  final void Function(SecretKey vaultKey) onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _isSetup => !StorageService.instance.hasVault;

  Future<void> _submit() async {
    setState(() { _error = null; _busy = true; });
    try {
      if (_isSetup) {
        await _createVault();
      } else {
        await _unlockVault();
      }
    } catch (e) {
      setState(() => _error = _isSetup ? 'Something went wrong creating the diary.' : 'Wrong password. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createVault() async {
    final p1 = _passwordCtrl.text;
    final p2 = _confirmCtrl.text;
    if (p1.length < 8) { setState(() => _error = 'Use at least 8 characters.'); return; }
    if (p1 != p2) { setState(() => _error = "Passwords don't match."); return; }

    final salt = CryptoService.randomBytes(16);
    final key = await CryptoService.deriveKey(p1, salt);
    final verifier = await CryptoService.encrypt(key, 'keep-vault-ok');

    await StorageService.instance.saveVaultMeta(VaultMeta(
      salt: CryptoService.bytesToB64(salt),
      verifier: verifier,
    ));

    widget.onUnlocked(key);
  }

  Future<void> _unlockVault() async {
    final meta = StorageService.instance.loadVaultMeta();
    if (meta == null) { setState(() => _error = 'No diary found on this device.'); return; }

    final salt = Uint8List.fromList(CryptoService.b64ToBytes(meta.salt));
    final key = await CryptoService.deriveKey(_passwordCtrl.text, salt);
    final check = await CryptoService.decrypt(key, meta.verifier);
    if (check != 'keep-vault-ok') { setState(() => _error = 'Wrong password. Try again.'); return; }

    widget.onUnlocked(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14172B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Card(
                color: const Color(0xFF1E2340),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 34), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Keep', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFFF6F1E4), fontFamily: 'serif')),
                      const Text('A PRIVATE DIARY', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Color(0xFF8A8FB0))),
                      const SizedBox(height: 24),
                      Text(_isSetup ? 'Set your password' : 'Welcome back',
                          style: const TextStyle(fontSize: 18, color: Color(0xFFF6F1E4), fontWeight: FontWeight.w600)),
                      if (_isSetup) ...[
                        const SizedBox(height: 6),
                        const Text(
                          "This unlocks your diary and encrypts every entry. There's no reset — write it down somewhere safe.",
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF8A8FB0), height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(_isSetup ? 'Choose a password' : 'Password'),
                      ),
                      if (_isSetup) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Confirm password'),
                          onSubmitted: (_) => _submit(),
                        ),
                      ] else
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          onSubmitted: (_) => _submit(),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: Color(0xFFC1573C), fontSize: 13)),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8A33D),
                          foregroundColor: const Color(0xFF0F1224),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_busy ? 'Please wait…' : (_isSetup ? 'Create diary' : 'Unlock')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A5080)),
        filled: true,
        fillColor: const Color(0xFF14172B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
