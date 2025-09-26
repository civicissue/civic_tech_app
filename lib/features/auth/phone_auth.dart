import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});
  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _verificationId;
  bool _sending = false;
  String _stage = 'phone'; // 'phone' | 'code'

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      verificationCompleted: (cred) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(cred);
          if (mounted) Navigator.pop(context, true);
        } catch (_) {}
      },
      verificationFailed: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
        setState(() => _sending = false);
      },
      codeSent: (verificationId, _) {
        setState(() {
          _verificationId = verificationId;
          _sending = false;
          _stage = 'code';
        });
        Future.delayed(const Duration(milliseconds: 100), () => FocusScope.of(context).requestFocus());
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _codeCtrl.text.trim());
      await FirebaseAuth.instance.signInWithCredential(cred);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  void _editNumber() {
    setState(() => _stage = 'phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _stage == 'phone'
              ? Column(
                  key: const ValueKey('phone'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Enter your phone number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone number (+1 555 555 5555)'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _sending ? null : _sendCode,
                      child: _sending
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send code'),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('code'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Code sent to ${_phoneCtrl.text.trim()}', style: const TextStyle(fontSize: 16)),
                        ),
                        TextButton(onPressed: _editNumber, child: const Text('Change')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Enter 6-digit code'),
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _verifyCode, child: const Text('Verify & Sign in')),
                  ],
                ),
        ),
      ),
    );
  }
}

class LinkPhoneSheet extends StatefulWidget {
  const LinkPhoneSheet({super.key});
  @override
  State<LinkPhoneSheet> createState() => _LinkPhoneSheetState();
}

class _LinkPhoneSheetState extends State<LinkPhoneSheet> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _verificationId;
  bool _sending = false;
  String _stage = 'phone'; // 'phone' | 'code'

  Future<void> _sendCode() async {
    setState(() => _sending = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      verificationCompleted: (cred) async {
        try {
          await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
          if (mounted) Navigator.pop(context, true);
        } catch (_) {}
      },
      verificationFailed: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
        setState(() => _sending = false);
      },
      codeSent: (verificationId, _) {
        setState(() {
          _verificationId = verificationId;
          _sending = false;
          _stage = 'code';
        });
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _codeCtrl.text.trim());
      await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link failed: $e')));
    }
  }

  void _editNumber() => setState(() => _stage = 'phone');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _stage == 'phone'
            ? Column(
                key: const ValueKey('link_phone'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Link phone number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (+1 555 555 5555)')),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _sending ? null : _sendCode, child: _sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 1)) : const Text('Send code')),
                ],
              )
            : Column(
                key: const ValueKey('link_code'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: Text('Code sent to ${_phoneCtrl.text.trim()}')),
                    TextButton(onPressed: _editNumber, child: const Text('Change')),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: _codeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Enter 6-digit code'), maxLength: 6),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _verifyCode, child: const Text('Verify & Link')),
                ],
              ),
      ),
    );
  }
}
