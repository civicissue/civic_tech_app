import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'phone_auth.dart';

final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  Future<void> _ensureUserDocAndToken(User user) async {
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'impactScore': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await users.doc(user.uid).collection('fcmTokens').doc(token).set({
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      }, SetOptions(merge: true));
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final provider = GoogleAuthProvider();
      final cred = await FirebaseAuth.instance.signInWithProvider(provider);
      await _ensureUserDocAndToken(cred.user!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E10),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Welcome to CivicTech', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _signInWithGoogle(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhoneSignInScreen())),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Continue with Phone'),
                  ),
                ],
              ),
            ),
          );
        }
        // Ensure user doc and token on rebuilds as well
        _ensureUserDocAndToken(user);
        return child;
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
    );
  }
}
