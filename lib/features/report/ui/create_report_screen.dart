import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../report/providers.dart';
import 'map_picker.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});
  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'pothole';
  GeoPoint? _location;
  String? _address;

  Future<void> _selectLocation(BuildContext context) async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initial: LatLng(pos.latitude, pos.longitude)),
      ),
    );
    if (picked != null) {
      final placemarks = await geo.placemarkFromCoordinates(
        picked.latitude,
        picked.longitude,
      );
      final line = placemarks.isNotEmpty
          ? '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}'
                .trim()
          : '${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}';
      setState(() {
        _location = GeoPoint(picked.latitude, picked.longitude);
        _address = line;
      });
      await ref
          .read(createReportControllerProvider.notifier)
          .setLocation(_location!, _address!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);
    final ctrl = ref.read(createReportControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              DropdownMenuItem(value: 'pothole', child: Text('Pothole')),
              DropdownMenuItem(value: 'garbage', child: Text('Garbage')),
              DropdownMenuItem(
                value: 'streetlight',
                child: Text('Streetlight'),
              ),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'other'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the issue (required)',
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (state.pickedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                state.pickedFile!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: ctrl.pickImage,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Add Photo (required)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _address != null ? _address! : 'No location selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _selectLocation(context),
                child: const Text('Select location'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.loading
                ? null
                : () async {
                    final desc = _descCtrl.text.trim();
                    if (desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Description is required'),
                        ),
                      );
                      return;
                    }
                    await ctrl.submit(category: _category, description: desc);
                    if (context.mounted &&
                        ref.read(createReportControllerProvider).reportId !=
                            null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted')),
                      );
                      _descCtrl.clear();
                      Navigator.of(context).maybePop();
                    }
                  },
            child: state.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}
