import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_empty.dart';
import '../providers/memorization_providers.dart';
import 'memorization_test_screen.dart';

class MemorizationScreen extends ConsumerWidget {
  const MemorizationScreen({super.key});

  void _showCreatePlanDialog(BuildContext context, WidgetRef ref) {
    int selectedSurah = 1;
    final startAyahController = TextEditingController(text: '1');
    final endAyahController = TextEditingController(text: '7');
    final daysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final maxVerses = quran.getVerseCount(selectedSurah);

            return AlertDialog(
              title: Text('خطة حفظ جديدة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اختر السورة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedSurah,
                      items: List.generate(114, (i) {
                        final num = i + 1;
                        return DropdownMenuItem(
                          value: num,
                          child: Text('سورة ${quran.getSurahNameArabic(num)}'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedSurah = val;
                            endAyahController.text = quran.getVerseCount(val).toString();
                          });
                        }
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startAyahController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'من آية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endAyahController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'إلى آية (حد أقصى $maxVerses)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المدة المستهدفة (بالأيام)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: GoogleFonts.tajawal()),
                ),
                ElevatedButton(
                  onPressed: () {
                    final start = int.tryParse(startAyahController.text) ?? 1;
                    final end = int.tryParse(endAyahController.text) ?? maxVerses;
                    final days = int.tryParse(daysController.text) ?? 7;

                    ref.read(memorizationNotifierProvider.notifier).createPlan(
                          surahNumber: selectedSurah,
                          surahName: quran.getSurahNameArabic(selectedSurah),
                          startAyah: start.clamp(1, maxVerses),
                          endAyah: end.clamp(start, maxVerses),
                          targetDays: days,
                        );
                    Navigator.pop(context);
                  },
                  child: Text('إنشاء الخطة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(memorizationNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الحفظ والمراجعة',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'خطة حفظ جديدة',
            onPressed: () => _showCreatePlanDialog(context, ref),
          ),
        ],
      ),
      body: plans.isEmpty
          ? AppEmpty(
              title: 'لا توجد خطط حفظ نشطة',
              subtitle: 'ابدأ بحفظ سورة من القرآن الكريم مع نظام التكرار والمراجعة الذكية',
              icon: Icons.psychology_rounded,
              action: ElevatedButton.icon(
                onPressed: () => _showCreatePlanDialog(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: Text('إنشاء خطة حفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                final percent = plan.progressPercentage;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2320) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'سورة ${plan.surahName}',
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'من الآية ${plan.startAyah.toArabic()} إلى ${plan.endAyah.toArabic()}',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تم حفظ: ${plan.memorizedCount.toArabic()} من ${plan.totalAyahs.toArabic()} آية',
                            style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(percent * 100).toInt().toArabic()}%',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Actions Row: Revision Test
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MemorizationTestScreen(plan: plan),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.quiz_rounded, size: 18),
                              label: Text('بدء اختبار التثبيت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (plan.weakAyahs.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${plan.weakAyahs.length.toArabic()} آيات تحتاج مراجعة',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
