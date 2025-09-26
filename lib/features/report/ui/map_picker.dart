import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initial;
  const MapPickerScreen({super.key, required this.initial});
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _pos = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _pos, zoom: 16),
        markers: {
          Marker(
            markerId: const MarkerId('m'),
            position: _pos,
            draggable: true,
            onDragEnd: (p) => setState(() => _pos = p),
          )
        },
        onTap: (p) => setState(() => _pos = p),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _pos),
        label: const Text('Confirm'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
