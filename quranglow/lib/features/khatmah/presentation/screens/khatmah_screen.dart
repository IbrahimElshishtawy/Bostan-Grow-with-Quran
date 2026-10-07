import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../providers/khatmah_providers.dart';

class KhatmahScreen extends ConsumerWidget {
  const KhatmahScreen({super.key});

  void _showCreatePlanDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: 'ختمة مباركة');
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('بدء ختمة جديدة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الختمة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('مدة الختمة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [7, 15, 30, 60].map((days) {
                        final isSel = selectedDays == days;
                        return ChoiceChip(
                          label: Text('$days يوم'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => selectedDays = days),
                        );
                      }).toList(),
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
                    final title = titleController.text.trim();
                    ref.read(khatmahNotifierProvider.notifier).createPlan(
                          title: title.isNotEmpty ? title : 'ختمة القرآن',
                          durationDays: selectedDays,
                        );
                    Navigator.pop(context);
                  },
                  child: Text('بدء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdatePageDialog(BuildContext context, WidgetRef ref, KhatmahPlan plan) {
    final controller = TextEditingController(text: plan.currentPage.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تحديث الصفحة الحالية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم آخر صفحة قرأتها (1 - 604)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= 604) {
                  ref.read(khatmahNotifierProvider.notifier).updateCurrentPage(plan.id, page);
                  Navigator.pop(context);
                }
              },
              child: Text('حفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(khatmahNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ختمات القرآن الكريم',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة ختمة جديدة',
            onPressed: () => _showCreatePlanDialog(context, ref),
          ),
        ],
      ),
      body: plans.isEmpty
          ? AppEmpty(
              title: 'لا توجد ختمة نشطة حالياً',
              subtitle: 'ابدأ ختمتك المباركة وحدد الأيام المناسبة لك لتقسيم وردك اليومي',
              icon: Icons.menu_book_rounded,
              action: ElevatedButton.icon(
                onPressed: () => _showCreatePlanDialog(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: Text('بدء ختمة جديدة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: plan.isCompleted
                          ? Colors.green.withOpacity(0.5)
                          : AppColors.gold.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan.title,
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: plan.isCompleted
                                  ? Colors.green.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              plan.isCompleted ? 'مكتملة بحمد الله' : '${plan.durationDays} يوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: plan.isCompleted ? Colors.green.shade700 : AppColors.primary,
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

                      // Progress stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الصفحة: ${plan.currentPage.toArabic()} من ٦٠٤',
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

                      // Details Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('المتبقي', '${plan.remainingPages.toArabic()} صفحة'),
                          _buildStatColumn('الأيام الباقية', '${plan.remainingDays.toArabic()} يوم'),
                          _buildStatColumn('الورد اليومي', '${plan.requiredDailyPages.toArabic()} صفحات'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showUpdatePageDialog(context, ref, plan),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: Text('تحديث الصفحة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () {
                              ref.read(khatmahNotifierProvider.notifier).deletePlan(plan.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
