// lib/features/ui/pages/player/widgets/speed_menu.dart
import 'package:flutter/material.dart';

class SpeedMenu extends StatefulWidget {
  const SpeedMenu({
    super.key,
    required this.onSelect,
    required this.currentSpeed,
  });
  final void Function(double) onSelect;
  final double currentSpeed;

  @override
  State<SpeedMenu> createState() => _SpeedMenuState();
}

class _SpeedMenuState extends State<SpeedMenu> {
  late double _speed = widget.currentSpeed;
  final _options = const [0.5, 0.75, 1.0, 1.25, 1.5];

  @override
  void didUpdateWidget(covariant SpeedMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSpeed != widget.currentSpeed) {
      _speed = widget.currentSpeed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'السرعة',
      onSelected: (v) {
        setState(() => _speed = v);
        widget.onSelect(v);
      },
      itemBuilder: (context) => _options
          .map(
            (v) => PopupMenuItem<double>(
              value: v,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (v == _speed)
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text('${v}x'),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              '${_speed}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
