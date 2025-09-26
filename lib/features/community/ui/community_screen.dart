import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../report/providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});
  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  static const _blr = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 12.5,
  );
  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(recentReportsProvider);
    return reports.when(
      data: (list) {
        final markers = list
            .map(
              (r) => Marker(
                markerId: MarkerId(r.id),
                position: LatLng(r.location.latitude, r.location.longitude),
                infoWindow: InfoWindow(
                  title: r.category,
                  snippet: r.description,
                ),
              ),
            )
            .toSet();
        return GoogleMap(
          initialCameraPosition: _blr,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
