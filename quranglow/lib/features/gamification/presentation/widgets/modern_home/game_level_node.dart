import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class GameLevelNode extends StatelessWidget {
  final GameLevel level;

  const GameLevelNode({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath = 'assets/images/gate_locked.png';
    final bool isCompleted = level.isCompleted;
    final bool isActive = level.isUnlocked && !level.isCompleted;
    final bool isLocked = !level.isUnlocked;

    if (isCompleted) {
      assetPath = 'assets/images/quran_completed.png';
    } else if (isActive) {
      assetPath = 'assets/images/gate_active.png';
    } else {
      assetPath = (level.sequence % 2 == 0)
          ? 'assets/images/gate_unlocked.png'
          : 'assets/images/gate_locked.png';
    }

    final title = 'آيات ${level.ayahStart}-${level.ayahEnd}';
    final subTitle = level.surahName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars Above Completed Nodes
        if (isCompleted)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              level.starsEarned > 0 ? level.starsEarned : 3,
              (x) => Icon(
                Icons.star_rounded,
                color: const Color(0xFFE0B566).withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          )
        else
          const SizedBox(height: 16),

        // Visual Asset
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 10,
              child: Container(
                width: 60,
                height: 15,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            Container(
                  width: isActive ? 130 : 110,
                  height: isActive ? 130 : 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isActive ? const Color(0xFFBDE156) : Colors.white)
                          .withValues(alpha: isActive ? 0.4 : 0.15),
                      width: 1.5,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 3.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  curve: Curves.easeInOutSine,
                ),

            if (isActive)
              Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBDE156).withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 2.seconds,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.1, 1.1),
                  )
                  .fadeOut(duration: 2.seconds),

            if (isActive)
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE082).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 1.5.seconds,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.1, 1.1),
                  ),

            Image.asset(
              assetPath,
              width: isActive ? 125 : (isLocked ? 115 : 105),
              height: isActive ? 125 : (isLocked ? 115 : 105),
              fit: BoxFit.contain,
            ),
          ],
        ),

        if (!isLocked)
          Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                subTitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
      ],
    );
  }
}
