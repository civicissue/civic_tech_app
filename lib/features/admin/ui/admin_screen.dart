import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);
    return reports.when(
      data: (list) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final r = list[i];
          return ListTile(
            title: Text(r.category.toUpperCase()),
            subtitle: Text(r.description ?? 'No description'),
            trailing: DropdownButton<String>(
              value: r.status,
              items: const [
                DropdownMenuItem(value: 'submitted', child: Text('submitted')),
                DropdownMenuItem(value: 'acknowledged', child: Text('acknowledged')),
                DropdownMenuItem(value: 'in_progress', child: Text('in_progress')),
                DropdownMenuItem(value: 'resolved', child: Text('resolved')),
                DropdownMenuItem(value: 'invalid', child: Text('invalid')),
              ],
              onChanged: (v) {
                if (v != null) _updateStatus(r.id, v);
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: list.length,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}