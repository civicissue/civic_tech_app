import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/user_doc.dart';

final topUsersProvider = StreamProvider<List<UserDoc>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('impactScore', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => UserDoc.fromMap(d.id, d.data())).toList());
});