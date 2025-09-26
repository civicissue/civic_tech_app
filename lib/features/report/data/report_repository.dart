import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../report/models/report.dart';

class ReportRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  Stream<List<ReportDoc>> myReports() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    // Avoid composite index by removing orderBy here; sort on client.
    return _db
        .collection('reports')
        .where('authorId', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ReportDoc.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.length > 50 ? list.sublist(0, 50) : list;
        });
  }

  Stream<List<ReportDoc>> recentReports({int limit = 50}) {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ReportDoc.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<XFile?> pickImage() async {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<String?> uploadImage(File file, {required String reportId}) async {
    final id = const Uuid().v4();
    final ref = _storage.ref().child('reports/$reportId/$id.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> createReport({
    required String category,
    required String description,
    required GeoPoint location,
    required String address,
    required String imageUrl,
  }) async {
    final uid = _auth.currentUser!.uid;
    final doc = _db.collection('reports').doc();
    final data = ReportDoc(
      id: doc.id,
      authorId: uid,
      category: category,
      status: 'submitted',
      description: description,
      imageUrl: imageUrl,
      location: location,
      address: address,
      createdAt: DateTime.now(),
    ).toMap();
    await doc.set(data);
    // naive impact score increment for demo
    await _db.collection('users').doc(uid).set({
      'impactScore': FieldValue.increment(1),
    }, SetOptions(merge: true));
    return doc.id;
  }
}
