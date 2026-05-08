/// Prayer Countdown Timer Widget
import 'package:flutter/material.dart';

class PrayerCountdown extends StatefulWidget {
  final Duration timeRemaining;
  final String prayerName;
  final VoidCallback? onCountdownComplete;

  const PrayerCountdown({
    super.key,
    required this.timeRemaining,
    required this.prayerName,
    this.onCountdownComplete,
  });

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.timeRemaining,
    )..forward();
  }

  @override
  void didUpdateWidget(PrayerCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRemaining != widget.timeRemaining) {
      _controller.dispose();
      _controller = AnimationController(
        vsync: this,
        duration: widget.timeRemaining,
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Next: ${widget.prayerName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final remaining = widget.timeRemaining -
                  Duration(milliseconds: (_controller.value * 1000).toInt());
              final hours = remaining.inHours;
              final minutes = remaining.inMinutes % 60;
              final seconds = remaining.inSeconds % 60;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimerUnit(hours.toString().padLeft(2, '0'), 'H'),
                  const SizedBox(width: 8),
                  const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'M'),
                  const SizedBox(width: 8),
                  const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildTimerUnit(seconds.toString().padLeft(2, '0'), 'S'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}
