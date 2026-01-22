import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BasicMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;

  const BasicMapWidget({
    Key? key,
    required this.initialCenter,
    this.initialZoom = 15.0,
  }) : super(key: key);

  @override
  State<BasicMapWidget> createState() => _BasicMapWidgetState();
}

class _BasicMapWidgetState extends State<BasicMapWidget> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.initialCenter,
        zoom: widget.initialZoom,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
        // Tile layer - the actual map
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.trackstar',
          // Respect OSM's tile usage policy
          maxZoom: 19,
        ),
        
        // Attribution (required by OSM)
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {}, // Could open OSM website
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}