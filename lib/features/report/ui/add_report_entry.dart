import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_report_screen.dart';

class AddReportEntry extends ConsumerWidget {
  const AddReportEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const Padding(
          padding: EdgeInsets.only(top: 8),
          child: CreateReportScreen(),
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Add report'),
    );
  }
}
