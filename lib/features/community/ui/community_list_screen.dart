import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/providers.dart';

class CommunityListScreen extends ConsumerWidget {
  const CommunityListScreen({super.key});

  Future<void> _verify(String reportId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final voteRef = FirebaseFirestore.instance.collection('reports').doc(reportId).collection('votes').doc(uid);
    final doc = await voteRef.get();
    if (doc.exists) {
      await voteRef.delete();
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'votesCount': FieldValue.increment(-1)});
    } else {
      await voteRef.set({'value': true, 'createdAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'votesCount': FieldValue.increment(1)});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);
    return reports.when(
      data: (list) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = list[i];
          return ListTile(
            tileColor: Colors.white.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(r.category.toUpperCase()),
            subtitle: Text(r.description ?? 'No description'),
            trailing: FilledButton.tonal(onPressed: () => _verify(r.id), child: const Text('Verify')),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}