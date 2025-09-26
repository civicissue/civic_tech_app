import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/providers.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReports = ref.watch(myReportsProvider);
    return myReports.when(
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
            trailing: Text(r.status),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}