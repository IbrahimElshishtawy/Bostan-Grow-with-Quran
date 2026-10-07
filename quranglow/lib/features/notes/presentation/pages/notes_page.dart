import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design_system/colors/app_palette.dart';
import '../../../design_system/components/app_components.dart';
import '../../../design_system/components/app_state_views.dart';
import '../../../design_system/spacing/app_spacing.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('ملاحظاتي القرآنية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: notesAsync.when(
        loading: () => const AppLoadingView(message: 'جاري تحميل الملاحظات...'),
        error: (err, _) => AppErrorView(
          message: 'حدث خطأ أثناء تحميل الملاحظات',
          onRetry: () => ref.refresh(notesListProvider),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const AppEmptyView(
              icon: Icons.note_alt_outlined,
              title: 'لا توجد ملاحظات بعد',
              subtitle: 'يمكنك تدوين خواطرك وتأملاتك القرآنية أثناء القراءة في المصحف.',
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final note = notes[index];
              return AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سورة رقم ${note.surahId} - الآية ${note.ayahId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.primary),
                        ),
                        Text(
                          'صفحة ${note.pageNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
