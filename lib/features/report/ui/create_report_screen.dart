import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../report/providers.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});
  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'pothole';
  GeoPoint? _location;

  Future<void> _getLocation() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _location = GeoPoint(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);
    final ctrl = ref.read(createReportControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'pothole', child: Text('Pothole')),
                DropdownMenuItem(value: 'garbage', child: Text('Garbage')),
                DropdownMenuItem(value: 'streetlight', child: Text('Streetlight')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: _getLocation, child: const Text('Use Location')),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Description (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          if (state.pickedFile != null) Image.file(state.pickedFile!, height: 160, fit: BoxFit.cover),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton.icon(onPressed: ctrl.pickImage, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Add Photo')),
            const SizedBox(width: 12),
            if (_location != null) Text('📍 ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}'),
          ]),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.loading
                ? null
                : () async {
                    await ctrl.submit(category: _category, description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(), location: _location);
                    if (mounted && ref.read(createReportControllerProvider).reportId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
                      setState(() {
                        _descCtrl.clear();
                      });
                    }
                  },
            child: state.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
          ),
          if (state.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(state.error!, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}