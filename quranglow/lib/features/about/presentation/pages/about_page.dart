import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _developerName = 'Ibrahim Elshishtawy';
  static const _facebook = 'https://www.facebook.com/p/Ibrahim-El-ShiShtawy-100025661886698/';
  static const _linkedin = 'https://www.linkedin.com/in/ibrahim-elshishtawy-0a67b334a/';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Premium Background with Subtle Pattern
            Positioned.fill(
              child: Image.asset(
                isDark ? 'assets/images/app_bg_dark.png' : 'assets/images/app_bg_light.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Image.asset(
                  'assets/images/islamic_pattern.png',
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),

            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 2. Animated Premium App Bar
                SliverAppBar(
                  expandedHeight: 220,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: isDark ? const Color(0xFF111A14) : Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF384E36).withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/bustan_icon.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 12),
                              const Text(
                                'بُستان القرآن',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 3. THE DEDICATION CARD (Sadaqah Jariyah)
                        _buildDedicationCard(context, isDark),
                        const SizedBox(height: 24),

                        // 4. QURANIC VERSE
                        _buildVerseSection(isDark),
                        const SizedBox(height: 24),

                        // 5. FEATURES LIST
                        _buildSectionHeader('مميزات التطبيق', Icons.auto_awesome_rounded, isDark),
                        const SizedBox(height: 12),
                        _buildFeaturesGrid(cs, isDark),
                        const SizedBox(height: 24),

                        // 6. DEVELOPER & SOCIAL
                        _buildSectionHeader('تواصل مع المطور', Icons.connect_without_contact_rounded, isDark),
                        const SizedBox(height: 12),
                        _buildDeveloperCard(context, isDark),
                        
                        const SizedBox(height: 40),
                        const Text(
                          'الإصدار 1.0.0',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDedicationCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF384E36).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 16),
          const Text(
            'هذا التطبيق صدقة جارية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'عن والدتي الغالية رحمها الله وغفر لها، وعن جميع أموات المسلمين. نسألكم الدعاء لهم بالرحمة والمغفرة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF384E36).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF384E36).withValues(alpha: 0.1)),
            ),
            child: Text(
              'اللهم ارحم أمواتنا وأموات المسلمين، واغفر لهم وتجاوز عن سيئاتهم، واجعل قبورهم روضة من رياض الجنة. اللهم ارحمنا إذا صرنا إلى ما صاروا إليه، وتوفنا وأنت راضٍ عنا، واجعل خير أعمالنا خواتيمها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildVerseSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF384E36).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF384E36).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '﴿ وَمَا تُقَدِّمُوا لِأَنفُسِكُم مِّنْ خَيْرٍ تَجِدُوهُ عِندَ اللَّهِ هُوَ خَيْرًا وَأَعْظَمَ أَجْرًا ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kitab',
              height: 1.8,
              color: isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B23),
              shadows: [
                Shadow(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '[ المزمل: 20 ]',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF384E36), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(ColorScheme cs, bool isDark) {
    final features = [
      ('مصحف تفاعلي', Icons.menu_book_rounded),
      ('مواقيت الصلاة', Icons.access_time_filled_rounded),
      ('أذكار المسلم', Icons.auto_stories_rounded),
      ('تحديد القبلة', Icons.explore_rounded),
      ('نظام مستويات', Icons.stars_rounded),
      ('تذكير آلي', Icons.notifications_active_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(features[index].$2, size: 20, color: const Color(0xFF384E36)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  features[index].$1,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeveloperCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF384E36),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _developerName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Mobile App Developer',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSocialBtn(
                  context,
                  'فيسبوك',
                  Icons.facebook_rounded,
                  const Color(0xFF1877F2),
                  _facebook,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialBtn(
                  context,
                  'لينكد إن',
                  Icons.work_rounded,
                  const Color(0xFF0A66C2),
                  _linkedin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String url,
  ) {
    return InkWell(
      onTap: () => _openLink(context, url, label),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openLink(
    BuildContext context,
    String value,
    String label,
  ) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
