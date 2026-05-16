import 'package:flutter/material.dart';

class PrayerAcademyHub extends StatelessWidget {
  const PrayerAcademyHub({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'دليل المصلي الفقهي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildAcademyTile(
                context: context,
                title: 'أركان الوضوء',
                subtitle: 'الفرائض الستة الأساسية',
                icon: Icons.opacity_rounded,
                gradientColors: [const Color(0xFF0288D1), const Color(0xFF00ACC1)],
                content: _wuduPillars,
              ),
              _buildAcademyTile(
                context: context,
                title: 'طريقة الوضوء',
                subtitle: 'شرح عملي خطوة بخطوة',
                icon: Icons.clean_hands_rounded,
                gradientColors: [const Color(0xFF00897B), const Color(0xFF43A047)],
                content: _wuduSteps,
              ),
              _buildAcademyTile(
                context: context,
                title: 'أدعية الوضوء',
                subtitle: 'ما يقال قبل وبعد الوضوء',
                icon: Icons.record_voice_over_rounded,
                gradientColors: [const Color(0xFF7E57C2), const Color(0xFF5C6BC0)],
                content: _wuduDuas,
              ),
              _buildAcademyTile(
                context: context,
                title: 'طرق الخشوع',
                subtitle: 'مفاتيح تدبر ولذة الصلاة',
                icon: Icons.spa_rounded,
                gradientColors: [const Color(0xFFD81B60), const Color(0xFF8E24AA)],
                content: _khushuKeys,
              ),
              _buildAcademyTile(
                context: context,
                title: 'إقامة الصلاة',
                subtitle: 'دعاء الإقامة والاستفتاح',
                icon: Icons.campaign_rounded,
                gradientColors: [const Color(0xFFE65100), const Color(0xFFF57C00)],
                content: _iqamahDuas,
              ),
              _buildAcademyTile(
                context: context,
                title: 'بعد إتمام الصلاة',
                subtitle: 'الأذكار الثابتة بعد السلام',
                icon: Icons.favorite_rounded,
                gradientColors: [const Color(0xFF1E88E5), const Color(0xFF3949AB)],
                content: _postPrayerDuas,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademyTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required _AcademyModule content,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailsSheet(context, title, content, gradientColors[0]),
          splashColor: gradientColors[0].withValues(alpha: 0.08),
          highlightColor: gradientColors[0].withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withValues(alpha: 0.15),
                        gradientColors[1].withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: gradientColors[0],
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: cs.onSurface,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(
    BuildContext context,
    String title,
    _AcademyModule data,
    Color accentColor,
  ) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            children: [
              // Top drag indicator & Header
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bookmark_outline_rounded, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          Text(
                            data.intro,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant.withValues(alpha: 0.4), height: 1),
              
              // Scrollable content list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  itemCount: data.items.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final step = data.items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Circular Index Counter
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Item text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: cs.onSurface,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.body,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                    fontFamily: 'Tajawal',
                                    height: 1.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------
// DATA STRUCTURES & MODEL MAPPING
// ----------------------------------------

class _AcademyModule {
  final String intro;
  final List<_ModuleItem> items;
  const _AcademyModule({required this.intro, required this.items});
}

class _ModuleItem {
  final String title;
  final String body;
  const _ModuleItem({required this.title, required this.body});
}

const _wuduPillars = _AcademyModule(
  intro: 'الفرائض الستة التي لا يصح الوضوء إلا بها جميعاً.',
  items: [
    _ModuleItem(
      title: '1. النية ومحلها القلب',
      body: 'استحضار القصد لرفع الحدث استجابةً لأمر الله تعالى.',
    ),
    _ModuleItem(
      title: '2. غسل الوجه كاملاً',
      body: 'ويشمل المضمضة والاستنشاق، وحدّ الوجه طولاً من منابت الشعر إلى أسفل اللحية وعرضاً بين الأذنين.',
    ),
    _ModuleItem(
      title: '3. غسل اليدين مع المرفقين',
      body: 'البدء من أطراف الأصابع وحتى تجاوز المرفق (الكوع) والحرص على عدم ترك أي موضع جاف.',
    ),
    _ModuleItem(
      title: '4. مسح الرأس كله',
      body: 'تمرير اليد المبتلة بالماء من مقدمة الرأس إلى مؤخرته، ويدخل في ذلك مسح الأذنين.',
    ),
    _ModuleItem(
      title: '5. غسل الرجلين مع الكعبين',
      body: 'غسل القدمين بالماء جيداً مع تعاهد الكعبين والعقب (المنطقة الخلفية) وتخليل الأصابع.',
    ),
    _ModuleItem(
      title: '6. الترتيب والموالاة',
      body: 'غسل الأعضاء بالترتيب المذكور، والموالاة بأن لا يؤخر غسل عضو حتى يجف الذي قبله.',
    ),
  ],
);

const _wuduSteps = _AcademyModule(
  intro: 'وصف الوضوء الكامل الموافق لسنة النبي ﷺ.',
  items: [
    _ModuleItem(
      title: 'التسمية وغسل الكفين',
      body: 'تبدأ بقول (بسم الله) ثم تغسل كفيك ثلاث مرات مع تخليل الأصابع.',
    ),
    _ModuleItem(
      title: 'المضمضة والاستنشاق',
      body: 'تأخذ غرفة بيمينك فتجعل نصفها لفمك وتتمضمض، ونصفها الآخر لأنفك وتستنشق ثم تستنثر بيسارك، وتفعل ذلك ثلاثاً.',
    ),
    _ModuleItem(
      title: 'غسل الوجه',
      body: 'تغسل وجهك كاملاً من منابت شعر الرأس إلى ما انحدر من اللحية، ومن الأذن إلى الأذن ثلاث مرات.',
    ),
    _ModuleItem(
      title: 'غسل اليدين إلى المرفقين',
      body: 'تغسل يدك اليمنى من أطراف الأصابع إلى المرفق ثلاثاً، ثم تفعل نفس الشيء بيدك اليسرى ثلاثاً.',
    ),
    _ModuleItem(
      title: 'مسح الرأس والأذنين',
      body: 'تبل يدك بالماء ثم تمسح رأسك من المقدمة للمؤخرة ثم تعود للمقدمة، ثم تمسح باطن الأذن بالسبابة وظاهرها بالإبهام (مرة واحدة).',
    ),
    _ModuleItem(
      title: 'غسل الرجلين للكعبين',
      body: 'تغسل رجلك اليمنى من أطراف الأصابع مع إدخال الكعبين ثلاثاً وتخلل بين الأصابع بخنصر يدك اليسرى، ثم اليسرى كذلك.',
    ),
  ],
);

const _wuduDuas = _AcademyModule(
  intro: 'الأذكار المأثورة المرافقة للوضوء لتحظى بالأجر العظيم.',
  items: [
    _ModuleItem(
      title: 'ما يقال قبل البدء بالوضوء',
      body: 'التسمية في أوله، لقوله ﷺ: "لا وضوء لمن لم يذكر اسم الله عليه"، فتقول: (بِسْمِ اللَّهِ).',
    ),
    _ModuleItem(
      title: 'الذكر العظيم بعد الفراغ من الوضوء',
      body: 'أشهد أن لا إله إلا الله وحده لا شريك له، وأشهد أن محمداً عبده ورسوله. (موجب لفتح أبواب الجنة الثمانية).',
    ),
    _ModuleItem(
      title: 'الزيادة المستحبة في الدعاء',
      body: 'اللهم اجعلني من التوابين واجعلني من المتطهرين، سبحانك اللهم وبحمدك أشهد أن لا إله إلا أنت أستغفرك وأتوب إليك.',
    ),
  ],
);

const _khushuKeys = _AcademyModule(
  intro: 'خطوات روحانية وعملية تساعدك على الخشوع وحضور القلب في الصلاة.',
  items: [
    _ModuleItem(
      title: '1. الاستعداد والتبكير',
      body: 'إسباغ الوضوء، وترديد الأذان، والمشي بسكينة ووقار للمسجد أو لسجادتك، وصلاة ركعتي السنة القبلية.',
    ),
    _ModuleItem(
      title: '2. استحضار عظمة الخالق',
      body: 'تذكر قبل التكبير أنك تقف بين يدي ملك الملوك وخالق الكون سبحانه وتعالى، فتأمل في كلماته.',
    ),
    _ModuleItem(
      title: '3. الطمأنينة في الأركان',
      body: 'أعطِ كل ركن حقه من الوقت؛ لا تستعجل بالركوع أو السجود، فالصلاة الهادئة تجلب طمأنينة القلب.',
    ),
    _ModuleItem(
      title: '4. النظر لموضع السجود',
      body: 'احرص على تثبيت عينيك في موضع سجودك طوال القيام، فهذا يمنع تشتت البصر ويجمع لك حواسك.',
    ),
    _ModuleItem(
      title: '5. تدبر المعاني والأذكار',
      body: 'فكر في معاني الفاتحة والسورة، واستشعر التنزيه في التسبيح "سبحان ربي العظيم" و"سبحان ربي الأعلى".',
    ),
  ],
);

const _iqamahDuas = _AcademyModule(
  intro: 'ما يستحب للمسلم عند سماع الإقامة والاستعداد للتكبير.',
  items: [
    _ModuleItem(
      title: 'ترديد ألفاظ الإقامة',
      body: 'يسن لك أن تقول مثلما يقول المقيم سراً، إلا عند قوله: (قد قامت الصلاة) فتقول مثلها أو تقول: (أقامها الله وأدامها).',
    ),
    _ModuleItem(
      title: 'الصلاة على النبي والدعاء',
      body: 'بعد انتهاء المقيم، تصلي على النبي ﷺ وتقول: "اللهم رب هذه الدعوة التامة والصلاة القائمة..." فالدعاء بين الأذان والإقامة لا يرد.',
    ),
    _ModuleItem(
      title: 'دعاء الاستفتاح (بعد التكبير مباشرة)',
      body: 'بعد تكبيرة الإحرام وقبل الفاتحة تقرأ: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلا إِلَهَ غَيْرُكَ".',
    ),
  ],
);

const _postPrayerDuas = _AcademyModule(
  intro: 'الأذكار الثابتة والجامعة للأجر بعد الانتهاء والتسليم من الصلاة.',
  items: [
    _ModuleItem(
      title: 'الاستغفار والتهليل',
      body: 'أستغفر الله (ثلاثاً). اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام. لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    ),
    _ModuleItem(
      title: 'التسبيح والتحميد والتكبير والختام',
      body: 'سبحان الله (33 مرة)، والحمد لله (33 مرة)، والله أكبر (33 مرة)، ثم تمام المئة: (لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير).',
    ),
    _ModuleItem(
      title: 'آية الكرسي والمعوذات',
      body: 'قراءة آية الكرسي (وهي مانع بين العبد والجنة إن مات)، ثم قراءة سورة الإخلاص، الفلق، والناس مرة واحدة بعد كل صلاة (وثلاثاً بعد الفجر والمغرب).',
    ),
  ],
);
