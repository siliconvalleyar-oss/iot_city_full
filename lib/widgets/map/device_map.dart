import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../config/palettes.dart';
import 'city_map_painter.dart';

class DeviceMap extends StatefulWidget {
  final List<Device> devices;
  final PaletteColors palette;
  final void Function(Device device)? onDeviceTap;
  final void Function(Device device)? onToggle;
  final void Function(Device device)? onTogglePower;

  const DeviceMap({
    super.key,
    required this.devices,
    required this.palette,
    this.onDeviceTap,
    this.onToggle,
    this.onTogglePower,
  });

  @override
  State<DeviceMap> createState() => _DeviceMapState();
}

class _DeviceMapState extends State<DeviceMap> {
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  String? _selectedId;

  static const double _minZoom = 0.3;
  static const double _maxZoom = 3.0;
  static const double _mapWidth = 800;
  static const double _mapHeight = 600;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onScaleStart: (details) {
              _lastFocalPoint = details.focalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                final scale = details.scale;
                final newZoom = (_zoom * scale).clamp(_minZoom, _maxZoom);
                final focalDelta = details.focalPoint - _lastFocalPoint;
                _pan += focalDelta;
                _zoom = newZoom;
                _lastFocalPoint = details.focalPoint;
              });
            },
            onTapUp: (details) {
              final painter = CityMapPainter(
                devices: widget.devices,
                zoom: _zoom,
                pan: _pan,
                selectedDeviceId: _selectedId,
              );
              final hit = painter.deviceAt(details.localPosition);
              if (hit != null) {
                setState(() => _selectedId = hit.id);
                widget.onDeviceTap?.call(hit);
              } else {
                setState(() => _selectedId = null);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: Size.infinite,
                painter: CityMapPainter(
                  devices: widget.devices,
                  zoom: _zoom,
                  pan: _pan,
                  selectedDeviceId: _selectedId,
                  showMesh: true,
                  showLabels: _zoom > 0.6,
                  showCoverage: true,
                ),
              ),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    final palette = widget.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.bg3,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _iconBtn(Icons.add, () {
                setState(() => _zoom = (_zoom * 1.3).clamp(_minZoom, _maxZoom));
              }),
              const SizedBox(width: 4),
              _iconBtn(Icons.remove, () {
                setState(() => _zoom = (_zoom / 1.3).clamp(_minZoom, _maxZoom));
              }),
              const SizedBox(width: 4),
              _iconBtn(Icons.center_focus_strong, () {
                setState(() {
                  _zoom = 1.0;
                  _pan = Offset.zero;
                });
              }),
            ],
          ),
          Text(
            '${widget.devices.length} devices  |  ${_zoom.toStringAsFixed(1)}x',
            style: TextStyle(color: palette.text2, fontSize: 9, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.palette.bg2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: widget.palette.border),
        ),
        child: Icon(icon, color: widget.palette.text2, size: 14),
      ),
    );
  }
}
