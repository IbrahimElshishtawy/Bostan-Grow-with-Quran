import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';

class MiniTasbihHub extends ConsumerStatefulWidget {
  const MiniTasbihHub({super.key});

  @override
  ConsumerState<MiniTasbihHub> createState() => _MiniTasbihHubState();
}

class _MiniTasbihHubState extends ConsumerState<MiniTasbihHub>
    with TickerProviderStateMixin {
  // Tasbih logic
  int _count = 0;
  int _adhkarIndex = 0;

  static const _adhkar = [
    'سُبْحَانَ اللهِ',
    'الْحَمْدُ لِلَّهِ',
    'لا إِلهَ إِلاَّ اللهُ',
    'اللهُ أَكْبَرُ',
    'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
    'لا حَوْلَ وَلا قُوَّةَ إِلاَّ بِاللهِ',
    'أَسْتَغْفِرُ اللهَ العَظِيمَ',
  ];

  // Animations
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  // Audio preview
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.90,
      upperBound: 1.0,
      value: 1.0,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _previewPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio =
              state.playing &&
              state.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _scaleController.forward(from: 0.90);
    setState(() {
      _count++;
    });
  }

  void _resetCount() {
    HapticFeedback.heavyImpact();
    setState(() {
      _count = 0;
    });
  }

  void _nextDhikr() {
    HapticFeedback.lightImpact();
    setState(() {
      _adhkarIndex = (_adhkarIndex + 1) % _adhkar.length;
    });
  }

  Future<void> _playSalawatAudio() async {
    if (_isPlayingAudio) {
      await _previewPlayer.stop();
      return;
    }

    setState(() => _isPlayingAudio = true);
    // To prevent IDE debugger pauses on caught exceptions, we use the guaranteed physical file path.
    // 'android/app/src/main/res/raw/salawat.mp3'
    const String salawatAsset =
        'android/app/src/main/res/raw/adhan_madinah.mp3';

    try {
      await _previewPlayer.setAsset(salawatAsset);
      await _previewPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تشغيل الصوت: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleSalawatNotification(bool enabled) async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;

    try {
      HapticFeedback.selectionClick();
      await ref.read(settingsProvider.notifier).setSalawatEnabled(enabled);

      final nextSettings = settings.copyWith(salawatEnabled: enabled);
      await NotificationService.instance.scheduleSalawat(
        enabled: enabled,
        intervalMinutes: nextSettings.salawatIntervalMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'تم تفعيل تذكير الصلاة على النبي ﷺ بنجاح'
                  : 'تم تعطيل تذكير الصلاة على النبي ﷺ',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final salawatActive = settings?.salawatEnabled ?? false;
    final salawatInterval = settings?.salawatIntervalMinutes ?? 15;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface, cs.surfaceContainerLow],
        ),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section - Professional mini Tasbih Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Circular glowing dynamic counter on the right (RTL friendly placement)
                GestureDetector(
                  onTap: _handleTap,
                  child: ScaleTransition(
                    scale: _scaleController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating outer gradient border ring for premium aesthetic
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _glowController.value * 2 * math.pi,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      cs.primary.withValues(alpha: 0.1),
                                      cs.primary,
                                      cs.primary.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner core tap container
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.25),
                                blurRadius: 12 * _pulseController.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: TextStyle(
                                  fontFamily: 'System',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onPrimaryContainer,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'تكرار',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Tajawal',
                                  color: cs.onPrimaryContainer.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Center Column - Dhikr Text reader
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'القارئ التسبيحي للفقراء',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _resetCount,
                            icon: Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            tooltip: 'تصفير العداد',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: _nextDhikr,
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.2, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey<int>(_adhkarIndex),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _adhkar[_adhkarIndex],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Uthman',
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: cs.outlineVariant.withValues(alpha: 0.4), height: 1),

          // Bottom Section - Salawat Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: salawatActive
                      ? Colors.redAccent
                      : cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تذكير الصلاة على النبي ﷺ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        salawatActive
                            ? 'مُفعل حاليًا، كل $salawatInterval دقيقة صوتيًا'
                            : 'تنبيه دوري صوتي يظهر بالإشعارات',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
                // Test Audio voice button
                IconButton.filledTonal(
                  onPressed: _playSalawatAudio,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isPlayingAudio
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                      key: ValueKey<bool>(_isPlayingAudio),
                      size: 18,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isPlayingAudio
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    foregroundColor: _isPlayingAudio
                        ? cs.onPrimary
                        : cs.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'استماع للصوت',
                ),
                const SizedBox(width: 8),
                // Toggle switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: salawatActive,
                    onChanged: _toggleSalawatNotification,
                    activeTrackColor: cs.primary.withValues(alpha: 0.4),
                    activeColor: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
