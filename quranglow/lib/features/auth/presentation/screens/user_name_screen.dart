import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/user_controller.dart';

class UserNameScreen extends ConsumerStatefulWidget {
  const UserNameScreen({super.key});

  @override
  ConsumerState<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends ConsumerState<UserNameScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final success = await ref
          .read(userControllerProvider.notifier)
          .registerUserName(name);

      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        final error = ref.read(userControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'حدث خطأ، يرجى المحاولة مرة أخرى',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Quran Illustration
                  Center(
                    child: SizedBox(
                      height: 180,
                      width: 180,
                      child: Lottie.asset(
                        AppAssets.quranLottie,
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            AppAssets.bustanIcon,
                            width: 120,
                            height: 120,
                          );
                        },
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'أهلاً بك في ${AppConstants.appName}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.primary,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 36),

                  // Card Container for Input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ما هو اسمك الكريم؟',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سيتم حفظ اسمك لترحيبك وإعداد وردك القرآني اليومي',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Text Field
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitName(),
                          autofocus: true,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'مثال: إبراهيم الشيشتاوي',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.gold,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى كتابة اسمك الكريم للمتابعة';
                            }
                            if (value.trim().length < 2) {
                              return 'الاسم قصير جداً';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: userState.isLoading ? null : _submitName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: userState.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ابدأ رحلتك المباركة',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_back_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Bottom spiritual hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        'خيركم من تعلّم القرآن وعلّمه',
                        style: GoogleFonts.amiri(
                          fontSize: 14,
                          color: isDark ? AppColors.goldLight : AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
