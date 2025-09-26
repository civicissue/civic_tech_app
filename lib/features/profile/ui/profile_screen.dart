import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/phone_auth.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _saving = false;
  bool _uploadingPhoto = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(text: u?.displayName ?? '');
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser!;
    await user.updateDisplayName(_nameCtrl.text.trim());
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': _nameCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'phoneNumber': user.phoneNumber,
      'email': user.email,
    }, SetOptions(merge: true));
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _linkEmail() async {
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();
      final cred = EmailAuthProvider.credential(email: email, password: pass);
      await FirebaseAuth.instance.currentUser!.linkWithCredential(cred);
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email linked. Verification sent.')));
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'email': user.email}, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link email failed: $e')));
    }
  }

  Future<void> _linkPhone() async {
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const LinkPhoneSheet());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'phoneNumber': user.phoneNumber}, SetOptions(merge: true));
      setState(() {});
    }
  }

  Future<void> _updateProfilePicture() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    
    setState(() => _uploadingPhoto = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/profile.jpg');
      await ref.putFile(File(xFile.path));
      final url = await ref.getDownloadURL();
      
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoURL': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) setState(() => _uploadingPhoto = false);
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: u?.photoURL != null ? NetworkImage(u!.photoURL!) : null,
                    child: u?.photoURL == null
                        ? Text((u?.displayName ?? 'U').characters.first.toUpperCase(), style: const TextStyle(fontSize: 18))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _updateProfilePicture,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: _uploadingPhoto
                            ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white))
                            : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(u?.email ?? u?.phoneNumber ?? 'Anonymous')),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _saving ? null : _saveProfile, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
            const Divider(height: 32),

            // Link Email
            const Text('Link Email', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _linkEmail, child: const Text('Link Email & Send Verification')),
            if (u?.email != null && u!.emailVerified == false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Email not verified', style: TextStyle(color: Colors.orange.shade300)),
              ),

            const Divider(height: 32),
            // Link Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phone: ${u?.phoneNumber ?? 'Not linked'}'),
                FilledButton.tonal(onPressed: _linkPhone, child: Text(u?.phoneNumber == null ? 'Link Phone' : 'Relink')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}