import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPickerDialog extends StatefulWidget {
  final LatLng? initialLocation;
  final double initialRadius;
  final Function(LatLng, double) onLocationSelected;

  const MapPickerDialog({
    super.key,
    this.initialLocation,
    this.initialRadius = 100.0,
    required this.onLocationSelected,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late LatLng _selectedLocation;
  late double _radius;
  MapController? _mapController;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ??
        const LatLng(-7.966620, 112.632629); // Default: Malang
    _radius = widget.initialRadius;
    // Jangan inisialisasi MapController di initState
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    // Pindahkan peta ke lokasi yang dipilih
    if (_mapController != null) {
      _mapController!.move(latLng, _currentZoom);
    }
  }

  void _handleRadiusChange(double value) {
    setState(() {
      _radius = value;
    });
  }

  void _saveAndClose() {
    widget.onLocationSelected(_selectedLocation, _radius);
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7FA8),
        title: const Text(
          'Pilih Lokasi di Peta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveAndClose,
          ),
        ],
      ),
      body: Column(
        children: [
          // Peta
          Expanded(
            child: FlutterMap(
              // MapController akan dibuat oleh FlutterMap
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: _currentZoom,
                maxZoom: 18.0,
                minZoom: 10.0,
                onTap: _handleMapTap,
                onMapReady: () {
                  // MapController sekarang sudah siap
                  setState(() {
                    // Update state untuk memicu rebuild jika perlu
                  });
                },
              ),
              children: [
                // Tile Layer (OpenStreetMap France)
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.client',
                  subdomains: const ['a', 'b', 'c'],
                ),

                // Marker Lokasi yang Dipilih
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),

                // CircleMarker dengan radius dalam meter
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation,
                      radius: _radius, // Radius dalam meter
                      useRadiusInMeter: true, // Penting: menggunakan meter, bukan pixel
                      color: const Color(0xFF1B7FA8).withOpacity(0.3),
                      borderColor: const Color(0xFF1B7FA8),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

                // ATTRIBUTION - WAJIB!
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                    TextSourceAttribution(
                      'OpenStreetMap France',
                      onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.fr/'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Control Panel dengan Slider dan Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi Terpilih:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Info Zoom Level
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7FA8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B7FA8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Slider Radius dengan Visual Feedback
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Radius Area:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B7FA8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_radius.round()} meter',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Slider dengan nilai-nilai preset
                    Slider(
                      value: _radius,
                      min: 10,
                      max: 1000,
                      divisions: 99,
                      label: '${_radius.round()} m',
                      activeColor: const Color(0xFF1B7FA8),
                      inactiveColor: Colors.grey.shade300,
                      thumbColor: const Color(0xFF1B7FA8),
                      onChanged: _handleRadiusChange,
                    ),
                    
                    // Preset radius values
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRadiusPreset(10, '10m'),
                        _buildRadiusPreset(100, '100m'),
                        _buildRadiusPreset(250, '250m'),
                        _buildRadiusPreset(500, '500m'),
                        _buildRadiusPreset(1000, '1km'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info: Lingkaran di peta akan menyesuaikan dengan slider
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info,
                        size: 18,
                        color: Color(0xFF1B7FA8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geser slider untuk mengubah ukuran radius lingkaran di peta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Gunakan Lokasi Saat Ini'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B7FA8),
                          side: const BorderSide(color: Color(0xFF1B7FA8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          _showSnackBar('Fitur lokasi saat ini akan diimplementasi nanti');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Simpan Lokasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7FA8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saveAndClose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk preset radius
  Widget _buildRadiusPreset(double value, String label) {
    return GestureDetector(
      onTap: () => _handleRadiusChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (_radius - value).abs() < 1 ? const Color(0xFF1B7FA8) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (_radius - value).abs() < 1 
                ? const Color(0xFF1B7FA8) 
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: (_radius - value).abs() < 1 ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}