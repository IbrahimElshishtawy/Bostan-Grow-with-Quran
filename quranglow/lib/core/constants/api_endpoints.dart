class ApiEndpoints {
  // 1. Prayer Times (مواقيت الصلاة) - Aladhan API
  static const String prayerTimesBaseUrl = 'https://api.aladhan.com/v1';
  static const String prayerTimingsByCity = '$prayerTimesBaseUrl/timingsByCity';
  static const String prayerTimingsByCoordinates = '$prayerTimesBaseUrl/timings';

  // 2. Quran Text & Editions (القرآن الكريم نصوص وسور) - Alquran Cloud API
  static const String alquranCloudBaseUrl = 'https://api.alquran.cloud/v1';
  static const String quranSurah = '$alquranCloudBaseUrl/surah'; // /{surahNumber}
  static const String quranAyah = '$alquranCloudBaseUrl/ayah'; // /{ayahNumber}
  static const String quranJuz = '$alquranCloudBaseUrl/juz'; // /{juzNumber}
  static const String quranPage = '$alquranCloudBaseUrl/page'; // /{pageNumber}
  static const String quranEditions = '$alquranCloudBaseUrl/edition';

  // 3. Quran Audio Recitations (القرآن الكريم صوت) - Quran.com API v4
  static const String quranComBaseUrl = 'https://api.quran.com/api/v4';
  static const String chapterRecitations = '$quranComBaseUrl/chapter_recitations'; // /{reciterId}
  static const String recitersList = '$quranComBaseUrl/resources/recitations';

  // 4. Tafsir (التفسير الميسر) - QuranEnc API
  static const String quranEncBaseUrl = 'https://quranenc.com/api/v1';
  static const String tafsirMoyassarSurah = '$quranEncBaseUrl/translation/sura/arabic_moyassar'; // /{surahNumber}
  static const String tafsirMoyassarAyah = '$quranEncBaseUrl/translation/aya/arabic_moyassar'; // /{surahNumber}/{ayahNumber}

  // 5. Hadiths (الأحاديث النبوية)
  static const String hadithPrimaryBaseUrl = 'https://hadis-api-id.vercel.app/hadith';
  static const String hadithAbuDawud = '$hadithPrimaryBaseUrl/abu-dawud';
  static const String hadithBukhari = '$hadithPrimaryBaseUrl/bukhari';
  static const String hadithMuslim = '$hadithPrimaryBaseUrl/muslim';
  static const String hadithEditionsCdn = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions.json';

  // 6. Azkar (الأذكار وحصن المسلم)
  static const String azkarJsonUrl = 'https://raw.githubusercontent.com/nawafalqari/azkar-api/56df51279ab6eb86dc2f6202c7de26c8948331c1/azkar.json';
  static const String hisnMuslimBaseUrl = 'https://www.hisnmuslim.com/api/ar'; // /{azkarId}.json

  // 7. Radio (راديو القرآن الكريم وإذاعات القراء)
  static const String radioJsonUrl = 'https://data-rosy.vercel.app/radio.json';
}
