import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../audio/presentation/screens/audio_player_screen.dart';
import '../../../auth/presentation/controllers/user_controller.dart';
import '../../../bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../../khatmah/presentation/providers/khatmah_providers.dart';
import '../../../khatmah/presentation/screens/khatmah_screen.dart';
import '../../../memorization/presentation/screens/memorization_screen.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../../quran/presentation/screens/mushaf_screen.dart';
import '../../../search/presentation/screens/quran_search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0;

  void _onSelectTab(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final widthClass = AppBreakpoints.getWidthClass(context);
    final isCompact = widthClass.isCompact;

    final pages = [
      _HomeDashboardView(
        onNavigateToTab: _onSelectTab,
      ),
      const MushafScreen(),
      const AudioPlayerScreen(),
      const MemorizationScreen(),
      const KhatmahScreen(),
    ];

    if (isCompact) {
      return Scaffold(
        body: IndexedStack(
          index: _selectedTabIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTabIndex,
          onDestinationSelected: _onSelectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'المصحف',
            ),
            NavigationDestination(
              icon: Icon(Icons.headphones_outlined),
              selectedIcon: Icon(Icons.headphones_rounded),
              label: 'الصوتيات',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology_rounded),
              label: 'الحفظ',
            ),
            NavigationDestination(
              icon: Icon(Icons.mosque_outlined),
              selectedIcon: Icon(Icons.mosque_rounded),
              label: 'الختمة',
            ),
          ],
        ),
      );
    } else {
      // Tablet / Desktop Adaptive Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: _onSelectTab,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppConstants.appName,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('الرئيسية'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: Text('المصحف'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.headphones_outlined),
                  selectedIcon: Icon(Icons.headphones_rounded),
                  label: Text('الصوتيات'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.psychology_outlined),
                  selectedIcon: Icon(Icons.psychology_rounded),
                  label: Text('الحفظ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.mosque_outlined),
                  selectedIcon: Icon(Icons.mosque_rounded),
                  label: Text('الختمة'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _HomeDashboardView extends ConsumerWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const _HomeDashboardView({
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userControllerProvider);
    final userName = userState.user?.name ?? 'ضيف الرحمن';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hijriNow = HijriCalendar.now();
    final hijriDateString =
        '${hijriNow.hDay.toArabic()} ${hijriNow.longMonthName} ${hijriNow.hYear.toArabic()} هـ';

    final mushafState = ref.watch(mushafControllerProvider);
    final activeKhatmah = ref.watch(activeKhatmahProvider);
    final syncMetadata = ref.watch(syncMetadataProvider);

    final lastPage = mushafState.currentPage;
    final lastPageData = quran.getPageData(lastPage);
    final currentSurahNum = lastPageData.isNotEmpty ? (lastPageData.first['surah'] as int) : 1;
    final currentSurahName = quran.getSurahNameArabic(currentSurahNum);

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.amiri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
        actions: [
          // Cloud Sync Status Action
          IconButton(
            icon: syncMetadata.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    syncMetadata.pendingOperationsCount > 0
                        ? Icons.cloud_queue_rounded
                        : Icons.cloud_done_outlined,
                    color: syncMetadata.pendingOperationsCount > 0
                        ? AppColors.gold
                        : AppColors.primaryLight,
                  ),
            tooltip: syncMetadata.pendingOperationsCount > 0
                ? 'مزامنة معلقة (${syncMetadata.pendingOperationsCount.toArabic()})'
                : 'البيانات متزامنة',
            onPressed: () {
              ref.read(syncManagerProvider).processQueue();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    syncMetadata.pendingOperationsCount > 0
                        ? 'جاري مزامنة التغييرات السحابية...'
                        : 'جميع بياناتك محفوظة ومتزامنة محلياً وسحابياً',
                    style: GoogleFonts.tajawal(),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'الإشارات المرجعية',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookmarksScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'البحث في القرآن',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Warm Greeting & Hijri Date Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'السلام عليكم، $userName',
                            style: GoogleFonts.tajawal(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: AppColors.goldLight, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '١ يوم',
                              style: GoogleFonts.tajawal(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hijriDateString,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Daily Ayah Quote
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // 2. Continue Reading Banner (متابعة القراءة)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onNavigateToTab(1),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'متابعة القراءة',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'سورة $currentSurahName — صفحة ${lastPage.toArabic()}',
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // 3. Active Khatmah Progress Card
            if (activeKhatmah != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              activeKhatmah.title,
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${activeKhatmah.currentPage.toArabic()} / ٦٠٤ صفحة',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: activeKhatmah.progressPercentage,
                        minHeight: 10,
                        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الورد اليومي: ${activeKhatmah.requiredDailyPages.toArabic()} صفحات',
                          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'متبقي ${activeKhatmah.remainingDays.toArabic()} يوم',
                          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

            // 4. Main Action Grid (Reading, Audio, Memorization, Khatma)
            Text(
              'الأنظمة الرئيسية',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.25,
              children: [
                _buildActionCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.primaryLight,
                  title: 'المصحف الشريف',
                  subtitle: 'سورة $currentSurahName - ص ${lastPage.toArabic()}',
                  isDark: isDark,
                  onTap: () => onNavigateToTab(1),
                ),
                _buildActionCard(
                  icon: Icons.headphones_rounded,
                  iconColor: AppColors.gold,
                  title: 'القرآن الصوتي',
                  subtitle: 'تلاوات مشاهير القراء',
                  isDark: isDark,
                  onTap: () => onNavigateToTab(2),
                ),
                _buildActionCard(
                  icon: Icons.psychology_rounded,
                  iconColor: const Color(0xFF6C5CE7),
                  title: 'حفظ ومراجعة',
                  subtitle: 'خطط الحفظ الذكية',
                  isDark: isDark,
                  onTap: () => onNavigateToTab(3),
                ),
                _buildActionCard(
                  icon: Icons.mosque_rounded,
                  iconColor: const Color(0xFF00B894),
                  title: 'ختمة القرآن',
                  subtitle: 'متابعة الورد والختمات',
                  isDark: isDark,
                  onTap: () => onNavigateToTab(4),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
