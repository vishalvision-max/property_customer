import 'package:flutter/material.dart';

class AreaSection extends StatefulWidget {
  final double minArea;
  final double maxArea;
  final Function(double, double) onAreaChanged;

  const AreaSection({
    super.key,
    required this.minArea,
    required this.maxArea,
    required this.onAreaChanged,
  });

  @override
  State<AreaSection> createState() => _AreaSectionState();
}

class _AreaSectionState extends State<AreaSection> {
  late double _currentMin;
  late double _currentMax;

  @override
  void initState() {
    super.initState();
    _currentMin = widget.minArea;
    _currentMax = widget.maxArea;
  }

  @override
  void didUpdateWidget(covariant AreaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minArea != widget.minArea ||
        oldWidget.maxArea != widget.maxArea) {
      _currentMin = widget.minArea;
      _currentMax = widget.maxArea;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Built-up Area',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min : ${_formatArea(_currentMin)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              'Max : ${_formatArea(_currentMax)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: const Color(0xFFFF8000),
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFFFF8000).withOpacity(0.12),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: RangeSlider(
            values: RangeValues(_currentMin, _currentMax),
            min: 0,
            max: 5000,
            divisions: 50,
            onChanged: (values) {
              setState(() {
                _currentMin = values.start;
                _currentMax = values.end;
              });
            },
            onChangeEnd: (values) {
              widget.onAreaChanged(values.start, values.end);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
              Text(
                '1000',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
              Text(
                '2000',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
              Text(
                '3000',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
              Text(
                '4000',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
              Text(
                'Any',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatArea(double value) {
    if (value >= 5000) return '5000 Sqft+';
    return '${value.toInt()} Sqft';
  }
}
