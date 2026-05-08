import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/memorization/application/memorization_controller.dart';
import 'package:quranglow/features/memorization/domain/memorization_models.dart';
import 'package:quranglow/features/memorization/presentation/pages/memorization_level_page.dart';

class LevelMapHomePage extends ConsumerWidget {
  const LevelMapHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(memorizationControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: asyncState.when(
        loading: () => const _LevelMapLoading(),
        error: (error, _) => _LevelMapError(
          error: error,
          onRetry: () =>
              ref.read(memorizationControllerProvider.notifier).reload(),
        ),
        data: (state) => _LevelMapContent(state: state),
      ),
    );
  }
}

class _LevelMapContent extends ConsumerWidget {
  const _LevelMapContent({required this.state});

  final MemorizationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dueReviews = state.dueReviewLevels(now);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface,
            Color.alphaBlend(
              const Color(0xFFEEF7F1).withValues(alpha: 0.72),
              cs.surface,
            ),
          ],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _PlayerHeader(state: state)),
          SliverToBoxAdapter(
            child: _ReviewSection(
              levels: dueReviews,
              fallbackLevel: state.currentLevel,
              onOpen: (level) => _openLevel(context, level),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeading(
              title: 'مسار الحفظ',
              subtitle:
                  '${_toArabicDigits(state.completedLevels)} من ${_toArabicDigits(state.totalLevels)} مستوى',
            ),
          ),
          SliverList.builder(
            itemCount: state.levels.length,
            itemBuilder: (context, index) {
              final level = state.levels[index];
              final previousX = index == 0 ? null : _pathX(index - 1);
              final currentX = _pathX(index);
              final nextX = index + 1 >= state.levels.length
                  ? null
                  : _pathX(index + 1);
              final nextUnlocked =
                  index + 1 < state.levels.length &&
                  state.levels[index + 1].isUnlocked;

              return _LevelPathRow(
                level: level,
                previousX: previousX,
                currentX: currentX,
                nextX: nextX,
                previousUnlocked: level.isUnlocked,
                nextUnlocked: nextUnlocked,
                onTap: () => _openLevel(context, level),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 98),
          ),
        ],
      ),
    );
  }

  void _openLevel(BuildContext context, MemorizationLevel level) {
    if (!level.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا المستوى مقفول. اجتز المستوى السابق بنجمتين على الأقل.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemorizationLevelPage(
          levelId: level.levelId,
          reviewMode: level.isCompleted,
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.state});

  final MemorizationState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = state.progressPercent;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) {
                    return IconButton.filledTonal(
                      tooltip: 'القائمة',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مسار الحفظ',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'خريطة يومية للحفظ والمراجعة',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  icon: Icons.favorite_rounded,
                  value: _toArabicDigits(state.profile.hearts),
                  label: 'قلوب',
                  color: const Color(0xFFE9445A),
                ),
                _StatChip(
                  icon: Icons.bolt_rounded,
                  value: _toArabicDigits(state.profile.totalXp),
                  label: 'XP',
                  color: const Color(0xFFEF9B22),
                ),
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  value: _toArabicDigits(state.profile.streak),
                  label: 'سلسلة',
                  color: const Color(0xFFE65F2B),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: cs.surface.withValues(alpha: 0.82),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.58),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نسبة التقدم',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${_toArabicDigits((progress * 100).round())}٪',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.10), cs.surface),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.levels,
    required this.fallbackLevel,
    required this.onOpen,
  });

  final List<MemorizationLevel> levels;
  final MemorizationLevel? fallbackLevel;
  final ValueChanged<MemorizationLevel> onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = levels.take(8).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            title: 'مراجعة اليوم',
            subtitle: 'المستويات التي حان وقت تثبيتها',
            compact: true,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            _NoReviewCard(level: fallbackLevel, onOpen: onOpen)
          else
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final level = items[index];
                  return _ReviewCard(level: level, onTap: () => onOpen(level));
                },
              ),
            ),
          if (items.length < levels.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'وباقي المراجعات تظهر بعد إنهاء هذه المجموعة.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoReviewCard extends StatelessWidget {
  const _NoReviewCard({required this.level, required this.onOpen});

  final MemorizationLevel? level;
  final ValueChanged<MemorizationLevel> onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Color.alphaBlend(
          const Color(0xFF1D9A8A).withValues(alpha: 0.10),
          cs.surface,
        ),
        border: Border.all(
          color: const Color(0xFF1D9A8A).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9A8A).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.done_all_rounded, color: Color(0xFF1D9A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'لا توجد مراجعات مستحقة الآن. تابع المستوى الحالي أو أعد مستوى سابق لتقوية الحفظ.',
              style: TextStyle(
                color: cs.onSurface,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (level != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => onOpen(level!),
              child: const Text('ابدأ'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.level, required this.onTap});

  final MemorizationLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 238,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface.withValues(alpha: 0.9),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.62)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  level.isBossReview
                      ? Icons.workspace_premium_rounded
                      : Icons.refresh_rounded,
                  color: level.isBossReview
                      ? const Color(0xFF7E57C2)
                      : cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.isBossReview ? 'تثبيت شامل' : 'مراجعة',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _Stars(stars: level.stars, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              level.surahName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'آيات ${_toArabicDigits(level.ayahStart)}-${_toArabicDigits(level.ayahEnd)}',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: level.memoryStrength / 100,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_toArabicDigits(level.memoryStrength)}٪',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _LevelPathRow extends StatelessWidget {
  const _LevelPathRow({
    required this.level,
    required this.previousX,
    required this.currentX,
    required this.nextX,
    required this.previousUnlocked,
    required this.nextUnlocked,
    required this.onTap,
  });

  final MemorizationLevel level;
  final double? previousX;
  final double currentX;
  final double? nextX;
  final bool previousUnlocked;
  final bool nextUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(currentX * 2 - 1, 0);

    return SizedBox(
      height: 140, // تم زيادة الارتفاع هنا من 118 إلى 140 لحل المشكلة
      child: CustomPaint(
        painter: _LevelPathPainter(
          previousX: previousX,
          currentX: currentX,
          nextX: nextX,
          previousActive: previousUnlocked,
          currentActive: level.isUnlocked,
          nextActive: nextUnlocked,
          color: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.outlineVariant,
        ),
        child: Align(
          alignment: alignment,
          child: _LevelNode(level: level, onTap: onTap),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.onTap});

  final MemorizationLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locked = !level.isUnlocked;
    final completed = level.isCompleted;
    final isBoss = level.isBossReview;
    final accent = locked
        ? cs.outline
        : isBoss
        ? const Color(0xFF7E57C2)
        : completed
        ? const Color(0xFF1D9A8A)
        : cs.primary;
    final fill = locked
        ? cs.surfaceContainerHighest
        : Color.alphaBlend(accent.withValues(alpha: 0.14), cs.surface);

    return Semantics(
      button: true,
      label: locked ? 'مستوى مقفول' : 'فتح مستوى ${level.sequence}',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedScale(
          scale: locked ? 0.94 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 116,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: isBoss ? 76 : 68,
                  height: isBoss ? 76 : 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: Border.all(
                      color: accent.withValues(alpha: locked ? 0.30 : 0.78),
                      width: isBoss ? 3 : 2,
                    ),
                    boxShadow: locked
                        ? null
                        : [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_rounded
                        : isBoss
                        ? Icons.workspace_premium_rounded
                        : completed
                        ? Icons.check_rounded
                        : Icons.menu_book_rounded,
                    color: accent,
                    size: isBoss ? 34 : 30,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level.isBossReview
                      ? 'تثبيت ${_toArabicDigits(level.sequence)}'
                      : 'مستوى ${_toArabicDigits(level.sequence)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: locked ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${level.surahName} ${_toArabicDigits(level.ayahStart)}-${_toArabicDigits(level.ayahEnd)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _Stars(stars: level.stars, size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars, required this.size});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: index < stars ? const Color(0xFFFFB332) : inactive,
        );
      }),
    );
  }
}

class _LevelPathPainter extends CustomPainter {
  const _LevelPathPainter({
    required this.previousX,
    required this.currentX,
    required this.nextX,
    required this.previousActive,
    required this.currentActive,
    required this.nextActive,
    required this.color,
    required this.inactiveColor,
  });

  final double? previousX;
  final double currentX;
  final double? nextX;
  final bool previousActive;
  final bool currentActive;
  final bool nextActive;
  final Color color;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final inactivePaint = Paint()
      ..color = inactiveColor.withValues(alpha: 0.46)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final node = Offset(currentX * size.width, size.height / 2);

    if (previousX != null) {
      final top = Offset(previousX! * size.width, 0);
      canvas.drawLine(
        top,
        node,
        previousActive && currentActive ? activePaint : inactivePaint,
      );
    }

    if (nextX != null) {
      final bottom = Offset(nextX! * size.width, size.height);
      canvas.drawLine(
        node,
        bottom,
        currentActive && nextActive ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter oldDelegate) {
    return previousX != oldDelegate.previousX ||
        currentX != oldDelegate.currentX ||
        nextX != oldDelegate.nextX ||
        previousActive != oldDelegate.previousActive ||
        currentActive != oldDelegate.currentActive ||
        nextActive != oldDelegate.nextActive ||
        color != oldDelegate.color ||
        inactiveColor != oldDelegate.inactiveColor;
  }
}

class _LevelMapLoading extends StatelessWidget {
  const _LevelMapLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                Text(
                  'نجهز خريطة الحفظ من السور والآيات الموجودة في التطبيق...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أول تشغيل قد يستغرق وقتًا لأن السور تُحفظ محليًا بعد التحميل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelMapError extends StatelessWidget {
  const _LevelMapError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 46, color: cs.error),
                const SizedBox(height: 14),
                const Text(
                  'تعذر إنشاء خريطة الحفظ',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _pathX(int index) {
  const points = [0.76, 0.52, 0.24, 0.42];
  return points[index % points.length];
}

String _toArabicDigits(num value) {
  const east = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final text = value.toString();
  final out = StringBuffer();
  for (final char in text.split('')) {
    final digit = int.tryParse(char);
    out.write(digit == null ? char : east[digit]);
  }
  return out.toString();
}
